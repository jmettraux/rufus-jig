#--
# Copyright (c) 2009-2010, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++

require 'ostruct'

require 'rufus/lru' # gem install rufus-lru

require 'rufus/jig/path'


module Rufus::Jig

  # The classical helper method, does a full copy of the given object.
  # Thanks Marshal.
  #
  def self.marshal_copy (o)

    Marshal.load(Marshal.dump(o))
  end

  # Keeping track of the HTTP status code and of the error message.
  #
  class HttpError < RuntimeError

    attr_reader :status

    def initialize (status, message)

      @status = status
      super(message)
    end
  end

  # A common error for all adapters in case of timeout.
  #
  class TimeoutError < RuntimeError

    def initialize (message=nil)

      super(message || 'timed out')
    end
  end

  class HttpResponse

    attr_reader :status, :headers, :body
    attr_reader :original

    def etag

      headers['ETag'] || headers['Etag'] || headers['etag']
    end
  end

  URI_REGEX = /(https?):\/\/([^@]+:[^@]+@)?([^\/]+)([^\?]*)(\?.+)?$/

  # The current URI lib is not UTF-8 friendly, so this is a workaround.
  # Temporary hopefully.
  #
  def self.parse_uri (s)

    m = URI_REGEX.match(s)

    scheme, uname, pass, host, port, path, query = if m

      ho, po = m[3].split(':')
      po = (po || 80).to_i

      query = m[5] ? m[5][1..-1] : nil

      un, pa = m[2] ? m[2][0..-2].split(':') : [ nil, nil ]

      [ m[1], un, pa, ho, po, m[4], query ]

    else

      pa, qu = s.split('?')

      [ nil, nil, nil, nil, nil, pa, qu ]
    end

    OpenStruct.new(
      :scheme => scheme,
      :host => host, :port => port,
      :path => path, :query => query,
      :username => uname, :password => pass)
  end

  # The current URI lib is not UTF-8 friendly, so this is a workaround.
  # Temporary hopefully.
  #
  def self.parse_host (s)

    u = parse_uri(s)

    u ? u.host : nil
  end

  # The base for the Rufus::Jig::Http class.
  #
  class HttpCore

    # mostly for debugging purposes
    #
    attr_reader :last_response

    # the path => [ etag, decoded_body] client cache
    #
    attr_reader :cache

    # the options for the http client
    #
    attr_reader :options

    # scheme, host and port, vanilla
    #
    attr_reader :scheme, :host, :port

    # The class of the error that should be raised when a request is not 2xx.
    #
    attr_accessor :error_class

    # Sometimes a URI is passed for initialization, if the URI contained a
    # path, it is stored in @_path (and not used).
    # Rufus::Jig::Couch uses it though.
    #
    attr_accessor :_path, :_query

    def initialize (*args)

      @options = args.last.is_a?(Hash) ? args.pop.dup : {}

      if args[1].is_a?(Fixnum) # host, port[, path]

        @scheme = 'http'
        @host, @port, @_path = args

      else # uri

        u = Rufus::Jig.parse_uri(args.first)

        @scheme = u.scheme
        @host = u.host
        @port = u.port

        @options[:basic_auth] ||= [ u.username, u.password ] if u.username

        if args[1]
          @_path, @_query = args[1].split('?')
        else
          @_path = u.path
          @_query = u.query
        end
      end

      @cache = LruHash.new((@options[:cache_size] || 35).to_i)

      if pf = @options[:prefix]
        @options[:prefix] = "/#{pf}" if (not pf.match(/^\//))
      end

      @error_class = @options[:error_class] || HttpError
    end

    def uri

      OpenStruct.new(:scheme => @scheme, :host => @host, :port => @port)
    end

    def get (path, opts={})

      request(:get, path, nil, opts)
    end

    def post (path, data, opts={})

      request(:post, path, data, opts)
    end

    def put (path, data, opts={})

      request(:put, path, data, opts)
    end

    def delete (path, opts={})

      request(:delete, path, nil, opts)
    end

    protected

    def request (method, path, data, opts={})

      raw = raw_expected?(opts)

      path = add_prefix(path, opts)
      path = add_params(path, opts)

      path = '/' if path == ''

      etag = opts[:etag]
      cached = @cache[path]
      if etag && cached && cached.first != etag
        # cached version is probably stale
        cached = nil
        opts.delete(:etag)
      end
      if ( ! etag) && cached
        opts[:etag] = cached.first
      end

      opts = rehash_options(opts)
      data = repack_data(data, opts)

      r = do_request(method, path, data, opts)

      @last_response = r

      unless raw

        return Rufus::Jig.marshal_copy(cached.last) if r.status == 304
        return nil if method == :get && r.status == 404
        return true if [ 404, 409 ].include?(r.status)

        raise @error_class.new(r.status, r.body) \
          if r.status >= 400 && r.status < 600
      end

      b = decode_body(r, opts)

      do_cache(method, path, r, b, opts)

      raw ? r : b
    end

    def raw_expected? (opts)

      raw = opts[:raw]

      raw == false ? false : raw || @options[:raw]
    end

    # Should work with GET and POST/PUT options
    #
    def rehash_options (opts)

      opts['Accept'] ||= (opts.delete(:accept) || 'application/json')
      opts['Accept'] = 'application/json' if opts['Accept'] == :json

      if ct = opts.delete(:content_type)
        opts['Content-Type'] = ct
      end
      if opts['Content-Type'] == :json
        opts['Content-Type'] = 'application/json'
      end

      if et = opts.delete(:etag)
        opts['If-None-Match'] = et
      end

      opts
    end

    def add_prefix (path, opts)

      host = Rufus::Jig.parse_host(path)

      return path if host

      elts = [ path ]

      if path.match(/^[^\/]/) && prefix = @options[:prefix]
        elts.unshift(prefix)
      end

      Path.join(*elts)
    end

    def add_params (path, opts)

      if params = opts[:params]

        return path if params.empty?

        params = params.inject([]) { |a, (k, v)|
          a << "#{k}=#{v}"; a
        }.join("&")

        return path.index('?') ? "#{path}&#{params}" : "#{path}?#{params}"
      end

      path
    end

    def repack_data (data, opts)

      return nil unless data

      data = if data.is_a?(String)
        data
      elsif (opts['Content-Type'] || '').match(/^application\/json/)
        Rufus::Json.encode(data)
      else
        data.to_s
      end

      #opts['Content-Length'] =
      #  (data.respond_to?(:bytesize) ? data.bytesize : data.size).to_s
        #
        # Patron doesn't play well with custom lengths : "56, 56" issue

      data
    end

    def do_cache (method, path, response, body, opts)

      etag = response.etag

      if etag.nil? || opts[:cache] == false || method == :delete
        @cache.delete(path)
        return
      end
      if method != :get && opts[:cache] != true
        @cache.delete(path)
        return
      end

      @cache[path] = [ etag, Rufus::Jig.marshal_copy(body) ]
    end

    def decode_body (response, opts)

      b = response.body
      ct = response.headers['Content-Type']

      if opts[:force_json] || (ct && ct.match(/^application\/json/))
        Rufus::Json.decode(b)
      else
        b
      end
    end
  end
end

#--
# now load an adapter
#++

if defined?(Net::HTTP::Persistent) # gem install net-http-persistent

  require 'rufus/jig/adapters/net_persistent'

elsif defined?(Patron) # gem install patron

  require 'rufus/jig/adapters/patron'

elsif defined?(EventMachine::HttpRequest)

  require 'rufus/jig/adapters/em'

else

  require 'rufus/jig/adapters/net'

end


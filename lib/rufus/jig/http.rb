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
  end

  URI_REGEX = /https?:\/\/([^\/]+)([^\?]*)(\?.+)?$/

  # The current URI lib is not UTF-8 friendly, so this is a workaround.
  # Temporary hopefully.
  #
  def self.parse_uri (s)

    m = URI_REGEX.match(s)

    host, port, path, query = if m

      h, p = m[1].split(':')
      p ||= 80

      query = m[3] ? m[3][1..-1] : nil

      [ h, p, m[2], query ]

    else

      p, q = s.split('?')

      [ nil, nil, p, q ]
    end

    OpenStruct.new(:host => host, :port => port, :path => path, :query => query)
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

    # host and port, vanilla
    #
    attr_reader :host, :port

    # The class of the error that should be raised when a request is not 2xx.
    #
    attr_accessor :error_class

    def initialize (host, port, opts)

      @host = host
      @port = port

      @options = opts.dup

      @cache = LruHash.new((opts[:cache_size] || 35).to_i)

      if pf = @options[:prefix]
        @options[:prefix] = "/#{pf}" if (not pf.match(/^\//))
      end

      @error_class = opts[:error_class] || HttpError
    end

    def close

      # default implementation does nothing
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

    def from_cache (path, opts)

      if et = opts[:etag]

        cached = @cache[path]

        if cached && cached.first != et
          #
          # cached version is perhaps stale
          #
          cached = nil
          opts.delete(:etag)
        end

        cached

      else

        nil
      end
    end

    def request (method, path, data, opts={})

      raw = raw_expected?(opts)

      path = add_prefix(path, opts)
      path = add_params(path, opts)

      path = '/' if path == ''

      cached = from_cache(path, opts)
      opts.delete(:etag) if (not cached) || method != :get

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

      if (method != :get) || (opts[:cache] == false)
        @cache.delete(path)
      elsif et = response.headers['Etag']
        @cache[path] = [ et, Rufus::Jig.marshal_copy(body) ]
      end
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


if defined?(Patron) # gem install patron

  require 'rufus/jig/adapters/patron'

elsif defined?(EventMachine::HttpRequest)

  require 'rufus/jig/adapters/em'

else

  require 'rufus/jig/adapters/net'

end

#--
#
# re-opening the HTTP class to add some class methods
#
#++
class Rufus::Jig::Http

  # Makes sense of arguments and extract an array that goes like
  # [ http, path, payload, opts ].
  #
  # Typical input :
  #
  #   a = Rufus::Jig::Http.extract_http(false, 'http://127.0.0.1:5984')
  #   a = Rufus::Jig::Http.extract_http(false, '127.0.0.1', 5984, '/')
  #   a = Rufus::Jig::Http.extract_http(true, 'http://127.0.0.1:5984', :payload)
  #
  def self.extract_http (payload_expected, *args)

    host, port = case args.first

      when Rufus::Jig::Http
        args.shift

      when /^http:\/\//
        u = Rufus::Jig.parse_uri(args.shift)
        args.unshift(u.path)
        [ u.host, u.port ]

      else
        [ args.shift, args.shift ]
    end

    port = port.to_i

    path = args.shift
    path = '/' if path == ''

    payload = payload_expected ? args.shift : nil

    opts = args.shift || {}

    raise(
      ArgumentError.new("option Hash expected, not #{opts.inspect}")
    ) unless opts.is_a?(Hash)

    http = host.is_a?(Rufus::Jig::Http) ?
      host :
      Rufus::Jig::Http.new(host, port, opts)

    [ http, path, payload, opts ]
  end
end


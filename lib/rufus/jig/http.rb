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


require 'rufus/lru' # gem install rufus-lru

require 'rufus/jig/path'


module Rufus::Jig

  # The classical helper method, does a full copy of the given object.
  # Thanks Marshal.
  #
  def self.marshal_copy(o)

    Marshal.load(Marshal.dump(o))
  end

  # Keeping track of the HTTP status code and of the error message.
  #
  class HttpError < RuntimeError

    attr_reader :status

    def initialize(status, message)

      @status = status
      super(message)
    end
  end

  # A common error for all adapters in case of timeout.
  #
  class TimeoutError < RuntimeError

    def initialize(message=nil)

      super(message || 'timed out')
    end
  end

  #
  # a Rufus::Jig wrapper for the server response.
  #
  class HttpResponse

    attr_reader :status, :headers, :body
    attr_reader :original

    def initialize(res)

      net_http_init(res)
    end

    def etag

      headers['ETag'] || headers['Etag'] || headers['etag']
    end

    protected

    # (leveraged by the patron adapter as well)
    #
    def net_http_init(net_http_response)

      @original = net_http_response
      @status = net_http_response.code.to_i
      @body = net_http_response.body
      @headers = {}
      net_http_response.each { |k, v|
        @headers[k.split('-').collect { |s| s.capitalize }.join('-')] = v
      }
    end
  end

  #
  # Rufus::Jig.parse_uri returns instances of this class.
  #
  class Uri

    attr_accessor :scheme
    attr_accessor :username, :password
    attr_accessor :host, :port
    attr_accessor :path, :query, :fragment

    def initialize(sc, us, ps, ho, po, pa, qu, fr)

      @scheme = sc
      @username = us
      @password = ps
      @host = ho
      @port = po
      @path = pa
      @query = qu
      @fragment = fr
    end

    def to_s

      tail = tail_to_s

      return tail unless @host

      up = ''
      up = "#{@username}:#{password}@" if @username

      "#{@scheme}://#{up}#{@host}:#{@port}#{tail}"
    end

    def tail_to_s

      tail = @path
      tail = "#{tail}?#{@query}" if @query
      tail = "#{tail}##{@fragment}" if @fragment

      tail
    end
  end

  URI_REGEX = /(https?):\/\/([^@]+:[^@]+@)?([^\/]+)(.*)?$/
  PATH_REGEX = /([^\?#]*)(\?[^#]+)?(#[^#]+)?$/

  # The current URI lib is not UTF-8 friendly, so this is a workaround.
  # Temporary hopefully.
  #
  def self.parse_uri(s)

    m = URI_REGEX.match(s)

    scheme, uname, pass, host, port, tail = if m

      ho, po = m[3].split(':')
      po = (po || 80).to_i

      un, pa = m[2] ? m[2][0..-2].split(':') : [ nil, nil ]

      [ m[1], un, pa, ho, po, m[4] ]

    else

      [ nil, nil, nil, nil, nil, s ]
    end

    m = PATH_REGEX.match(tail)

    path, query, fragment = [ m[1], m[2], m[3] ]

    port = 443 if scheme == 'https' && port == 80
    query = query[1..-1] if query
    fragment = fragment[1..-1] if fragment

    Uri.new(scheme, uname, pass, host, port, path, query, fragment)
  end

  # The current URI lib is not UTF-8 friendly, so this is a workaround.
  # Temporary hopefully.
  #
  def self.parse_host(s)

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
    attr_accessor :_path, :_query, :_fragment

    def initialize(*args)

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
          uu = Rufus::Jig.parse_uri(args[1])
          @_path = uu.path
          @_query = uu.query
          @_fragment = uu.fragment
        else
          @_path = u.path
          @_query = u.query
          @_fragment = u.fragment
        end
      end

      @_path ||= ''

      @cache = LruHash.new((@options[:cache_size] || 35).to_i)

      if pf = @options[:prefix]
        @options[:prefix] = "/#{pf}" if (not pf.match(/^\//))
      end

      @error_class = @options[:error_class] || HttpError
    end

    def uri

      Uri.new(@scheme, nil, nil, @host, @port, nil, nil, nil)
    end

    def get(path, opts={})

      request(:get, path, nil, opts)
    end

    def post(path, data, opts={})

      request(:post, path, data, opts)
    end

    def put(path, data, opts={})

      request(:put, path, data, opts)
    end

    def delete(path, opts={})

      request(:delete, path, nil, opts)
    end

    protected

    def request(method, path, data, opts={})

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

      res = do_request(method, path, data, opts)

      respond(method, path, opts, cached, res)
    end

    def respond(method, path, opts, cached, res)

      @last_response = res

      raw = opts[:raw]
      raw == false ? false : raw || @options[:raw]

      unless raw

        return Rufus::Jig.marshal_copy(cached.last) if res.status == 304
        return nil if method == :get && res.status == 404
        return true if [ 404, 409 ].include?(res.status)

        if res.status >= 400 && res.status < 600
          #File.open('error.html', 'wb') { |f| f.puts(res.body) }
          raise @error_class.new(res.status, res.body)
        end
      end

      b = decode_body(res, opts)

      do_cache(method, path, res, b, opts)

      raw ? res : b
    end

    # Should work with GET and POST/PUT options
    #
    def rehash_options(opts)

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

    def add_prefix(path, opts)

      host = Rufus::Jig.parse_host(path)

      return path if host

      elts = [ path ]

      if path.match(/^[^\/]/) && prefix = @options[:prefix]
        elts.unshift(prefix)
      end

      Path.join(*elts)
    end

    def add_params(path, opts)

      if params = opts[:params]

        return path if params.empty?

        params = params.inject([]) { |a, (k, v)|
          a << "#{k}=#{v}"; a
        }.join("&")

        return path.index('?') ? "#{path}&#{params}" : "#{path}?#{params}"
      end

      path
    end

    APP_JSON_REGEX = /^application\/json/

    def repack_data(data, opts)

      return nil if data == nil
      return data if data.is_a?(String)

      ct = opts['Content-Type'] || ''

      if APP_JSON_REGEX.match(ct)
        return Rufus::Json.encode(data)
      end
      if ct == '' && (data.is_a?(Array) || data.is_a?(Hash))
        opts['Content-Type'] = 'application/json'
        return Rufus::Json.encode(data)
      end

      data.to_s
    end

    def do_cache(method, path, response, body, opts)

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

    def decode_body(response, opts)

      b = response.body
      ct = response.headers['Content-Type']

      if opts[:force_json] || (ct && APP_JSON_REGEX.match(ct))
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


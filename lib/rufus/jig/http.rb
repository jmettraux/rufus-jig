#--
# Copyright (c) 2009-2009, John Mettraux, jmettraux@gmail.com
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

require 'uri'

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

  class HttpResponse

    attr_reader :status, :headers, :body
    attr_reader :original
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
      @options = opts

      @cache = LruHash.new((opts[:cache_size] || 35).to_i)

      if pf = @options[:prefix]
        @options[:prefix] = "/#{pf}" if (not pf.match(/^\//))
      end

      @error_class = opts[:error_class] || HttpError
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

      cached = from_cache(path, opts)
      opts.delete(:etag) if not cached

      opts = rehash_options(opts)
      data = repack_data(data, opts)

      r = send("do_#{method}", path, data, opts)

      @last_response = r

      unless raw

        return Rufus::Jig.marshal_copy(cached.last) if r.status == 304
        return nil if method == :get && r.status == 404

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

      uri = URI.parse( path )

      if !uri.host.nil?
        return uri.to_s

      else
        uri.host.nil?

        elts = [ path ]

        if path.match(/^[^\/]/) && prefix = @options[:prefix]
          elts.unshift(prefix)
        end

        return Path.join(*elts)
      end
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

      return data if data.nil? || data.is_a?(String)

      return Rufus::Jig::Json.encode(data) \
        if (opts['Content-Type'] || '').match(/^application\/json/)

      data.to_s
    end

    def do_cache (method, path, response, body, opts)

      if method == :delete || (opts[:cache] == false)
        @cache.delete(path)
      elsif et = response.headers['Etag']
        @cache[path] = [ et, Rufus::Jig.marshal_copy(body) ]
      end
    end

    def decode_body (response, opts)

      b = response.body
      ct = response.headers['Content-Type']

      if ct && ct.match(/^application\/json/)
        Rufus::Jig::Json.decode(b)
      else
        b
      end
    end
  end
end


if defined?(Patron) # gem install patron

  class Rufus::Jig::HttpResponse

    def initialize (patron_res)

      @original = patron_res
      @status = patron_res.status
      @headers = patron_res.headers
      @body = patron_res.body
    end
  end

  class Rufus::Jig::Http < Rufus::Jig::HttpCore

    def initialize (host, port, opts={})

      super(host, port, opts)

      @patron = Patron::Session.new
      @patron.base_url = "#{host}:#{port}"

      @patron.headers['User-Agent'] =
        opts[:user_agent] ||
        "#{self.class} #{Rufus::Jig::VERSION} (patron)"
    end

    protected

    def do_get (path, data, opts)

      @patron.get(path, opts)
    end

    def do_post (path, data, opts)

      @patron.post(path, data, opts)
    end

    def do_put (path, data, opts)

      opts['Expect'] = '' unless @options[:expect]

      @patron.put(path, data, opts)
    end

    def do_delete (path, data, opts)

      @patron.delete(path, opts)
    end
  end

elsif defined?( EventMachine::HttpRequest )

  class Rufus::Jig::HttpResponse

    def initialize( em_client )

      @original = [ em_client, em_client.response ]

      @status = em_client.response_header.status
      @headers = response_headers( em_client.response_header )
      @body = em_client.response
    end

    protected

    def response_headers( hash )
      hash.inject({}) do |headers, (key, value)|
        key = key.downcase.split('_').map { |c| c.capitalize }.join('-')
        headers[ key ] = value
        headers
      end
    end
  end

  class Rufus::Jig::Http < Rufus::Jig::HttpCore

    def initialize (host, port, opts={})

      super(host, port, opts)

      @em_host = host
      @em_port = port

      @em_ua = opts[:user_agent] || "#{self.class} #{Rufus::Jig::VERSION} (em)"
    end

    protected

    def do_get( path, data, opts )
      http = em_request( path ).get( :head => request_headers(opts) )

      em_response( http )
    end

    def do_post( path, data, opts )
      http = em_request( path ).post( :body => data, :head => request_headers(opts) )

      em_response( http )
    end

    def do_delete( path, data, opts )
      http = em_request( path ).delete( :head => request_headers( opts ) )

      em_response( http )
    end

    def do_put( path, data, opts )
      http = em_request( path ).put( :body => data, :head => request_headers( opts ) )

      em_response( http )
    end

    def em_request( uri = '/' )
      uri = URI.parse( uri )
      uri = URI::HTTP.build(
        :host => ( uri.host || @em_host ),
        :port => ( uri.port || @em_port ),
        :path => uri.path,
        :query => uri.query
      )

      EventMachine::HttpRequest.new( uri.to_s )
    end

    def em_response( em_client )
      th = Thread.current

      em_client.callback {
        th.wakeup
      }

      Thread.stop

      Rufus::Jig::HttpResponse.new( em_client )
    end

    def request_headers( options )
      headers = { 'user-agent' => @em_ua }

      %w[ Accept If-None-Match Content-Type ].each do |k|
        headers[k] = options[k] if options.has_key?( k )
      end

      headers
    end
  end

else

  require 'net/http'

  class Rufus::Jig::HttpResponse

    def initialize (nh_res)

      @original = nh_res
      @status = nh_res.code.to_i
      @body = nh_res.body
      @headers = {}
      nh_res.each { |k, v|
        @headers[k.split('-').collect { |s| s.capitalize }.join('-')] = v
      }
    end
  end

  class Rufus::Jig::Http < Rufus::Jig::HttpCore

    def initialize (host, port, opts={})

      super(host, port, opts)

      @http = Net::HTTP.new(host, port)

      to = opts[:timeout]
      if to
        to = to.to_i
        @http.open_timeout = to
        @http.read_timeout = to
      end

      @options[:user_agent] =
        opts[:user_agent] ||
        "#{self.class} #{Rufus::Jig::VERSION} (net/http)"
    end

    protected

    def do_get (path, data, opts)

      do_request(:get, path, data, opts)
    end

    def do_post (path, data, opts)

      do_request(:post, path, data, opts)
    end

    def do_put (path, data, opts)

      do_request(:put, path, data, opts)
    end

    def do_delete (path, data, opts)

      do_request(:delete, path, data, opts)
    end

    def do_request (method, path, data, opts)

      path = '/' if path == ''

      req = eval("Net::HTTP::#{method.to_s.capitalize}").new(path)

      req['User-Agent'] = options[:user_agent]
      opts.each { |k, v| req[k] = v if k.is_a?(String) }

      req.body = data ? data : ''

      Rufus::Jig::HttpResponse.new(@http.start { @http.request(req) })
    end
  end

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

    http = case args.first

      when Rufus::Jig::Http
        args.shift

      when /^http:\/\//
        u = URI.parse(args.shift)
        args.unshift(u.path)
        Rufus::Jig::Http.new(u.host, u.port)

      else
        Rufus::Jig::Http.new(args.shift, args.shift)
    end

    path = args.shift
    path = '/' if path == ''

    payload = payload_expected ? args.shift : nil

    opts = args.shift || {}

    raise(
      ArgumentError.new("option Hash expected, not #{opts.inspect}")
    ) unless opts.is_a?(Hash)

    [ http, path, payload, opts ]
  end
end


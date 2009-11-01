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

require 'rufus/lru' # gem install rufus-lru


module Rufus::Jig

  class HttpError < RuntimeError

    attr_reader :status

    def initialize (status, message)

      @status = status
      super(message)
    end
  end

  class HttpCore

    attr_reader :last_response

    def initialize (host, port, opts)

      @host = host
      @port = port
      @opts = opts

      @cache = LruHash.new((opts[:cache_size] || 100).to_i)
    end

    def get (path, opts={})

      path = add_prefix(path)

      cached = opts[:etag] ? @cache[path] : nil

      opts = rehash_options(opts)

      r = do_get(path, opts)

      @last_response = r

      return cached if r.status == 304
      return nil if r.status == 404
      raise HttpError.new(r.status, r.body) if r.status >= 500 && r.status < 600

      b = r.body

      if r.headers['Content-Type'].match(/^application\/json/)
        b = Rufus::Jig::Json.decode(b)
      end

      @cache[path] = b if etag = r.headers['Etag']

      b
    end

    protected

    # Should work with GET and POST/PUT options
    #
    def rehash_options (opts)

      opts['Accept'] ||= (opts.delete(:accept) || 'application/json')

      if ct = opts.delete(:content_type)
        opts['Content-Type'] = ct
      end

      if et = opts.delete(:etag)
        opts['If-None-Match'] = et
      end

      opts
    end

    def add_prefix (path)

      if prefix = @opts[:prefix]
        "#{prefix}#{path}"
      else
        path
      end
    end
  end
end


if defined?(Patron) # gem install patron

  class Rufus::Jig::Http < Rufus::Jig::HttpCore

    def initialize (host, port, opts={})

      super(host, port, opts)

      @patron = Patron::Session.new
      @patron.base_url = "#{host}:#{port}"

      @patron.headers['User-Agent'] =
        opts[:user_agent] || "#{self.class} #{Rufus::Jig::VERSION}"
    end

    def post (path, data, opts={})

      @patron.post(add_prefix(path), data, rehash_options(opts))
    end

    def put (path, data, opts={})

      @patron.put(add_prefix(path), data, rehash_options(opts))
    end

    def delete (path, opts={})

      @patron.delete(add_prefix(path), opts)
    end

    protected

    def do_get (path, opts)

      @patron.get(path, opts)
    end
  end

else

  # TODO : use Net:HTTP

end


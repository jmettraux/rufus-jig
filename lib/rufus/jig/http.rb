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

  class HttpCore

    attr_reader :last_response

    def initialize (host, port, opts)

      @host = host
      @port = port
      @opts = opts

      @cache = LruHash.new((opts[:cache_size] || 100).to_i)
    end

    def get (path, opts={})

      opts = expand_options(opts)

      r = do_get(path, opts)

      @last_response = r

      if r.status == 304
      end

      b = r.body

      if r.headers['Content-Type'].match(/^application\/json/)
        b = Rufus::Jig::Json.decode(b)
      end

      if etag = r.headers['Etag']
        @cache[path] = [ etag, b ]
      end

      b
    end

    protected

    def expand_options (opts)

      opts['Accept'] ||= (opts.delete(:accept) || 'application/json')

      opts
    end
  end
end


if defined?(Patron) # gem install patron

  class Rufus::Jig::Http < Rufus::Jig::HttpCore

    def initialize (host, port, options={})

      super(host, port, options)

      @patron = Patron::Session.new
      @patron.base_url = "#{host}:#{port}"
      @patron.headers['User-Agent'] = "#{self.class} #{Rufus::Jig::VERSION}"
    end

    protected

    def do_get (path, opts)

      @patron.get(path, opts)
    end
  end

elsif defined?(RestClient) # gem install rest_client

  raise NotImplementedError.new

else

  raise "found no HTTP client, please install gem 'patron' or 'rest_client'"
end


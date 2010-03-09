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

require 'thread'
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

    @http.open_timeout = 1
      # connection timeout

    if to = opts[:timeout]
      to = to.to_i
      @http.read_timeout = (to < 1) ? nil : to
    else
      @http.read_timeout = 5 # like Patron
    end

    @options[:user_agent] =
      opts[:user_agent] ||
      "#{self.class} #{Rufus::Jig::VERSION} (net/http)"

    @mutex = Mutex.new
  end

  def variant
    :net
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

    @mutex.synchronize do

      path = '/' if path == ''

      req = eval("Net::HTTP::#{method.to_s.capitalize}").new(path)

      req['User-Agent'] = options[:user_agent]
      opts.each { |k, v| req[k] = v if k.is_a?(String) }

      req.body = data ? data : ''

      Rufus::Jig::HttpResponse.new(@http.start { |h| h.request(req) })
    end
  end
end


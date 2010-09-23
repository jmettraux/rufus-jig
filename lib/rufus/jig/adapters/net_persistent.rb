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


# TODO adapters/net_response.rb
#
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

    @options[:user_agent] ||=
      "#{self.class} #{Rufus::Jig::VERSION} (net/http/persistent)"

    @http = Net::HTTP::Persistent.new
  end

  def variant
    :net_persistent
  end

  protected

#  def get_http (opts)
#
#    http = Net::HTTP.new(@host, @port)
#
#    http.open_timeout = 5
#      # connection timeout
#
#    if to = (opts[:timeout] || @options[:timeout])
#      to = to.to_i
#      http.read_timeout = (to < 1) ? nil : to
#    else
#      http.read_timeout = 5 # like Patron
#    end
#
#    http
#  end

  def do_request (method, path, data, opts)

    path = '/' if path == ''

    req = eval("Net::HTTP::#{method.to_s.capitalize}").new(path)

    req['User-Agent'] = @options[:user_agent]
    opts.each { |k, v| req[k] = v if k.is_a?(String) }

    req.body = data ? data : ''

    begin
      Rufus::Jig::HttpResponse.new(@http.request(uri, req))
    rescue Timeout::Error => te
      raise Rufus::Jig::TimeoutError
    end
  end
end


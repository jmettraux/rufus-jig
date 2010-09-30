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


require 'rufus/jig/adapters/net_response'


#
# Re-opening Net::HTTP::Persistent to add a shutdown_in_all_threads method.
#
class Net::HTTP::Persistent

  # Shuts down this instance's connection in all the threads.
  #
  # (to avoid too many open files issues).
  #
  def shutdown_in_all_threads

    Thread.list.each do |t|

      if cons = t[@connection_key]
        cons.each { |_, connection| connection.finish rescue IOError }
      end

      t[@connection_key] = nil
      t[@request_key] = nil
    end
  end
end


class Rufus::Jig::Http < Rufus::Jig::HttpCore

  def initialize (*args)

    super(*args)

    @options[:user_agent] ||=
      "#{self.class} #{Rufus::Jig::VERSION} (net/http/persistent)"

    @http = Net::HTTP::Persistent.new
  end

  def variant
    :net_persistent
  end

  # Closes the connection
  #
  def close

    #@http.shutdown
    @http.shutdown_in_all_threads
  end

  protected

  def do_request (method, path, data, opts)

    path = '/' if path == ''

    req = eval("Net::HTTP::#{method.to_s.capitalize}").new(path)

    req['User-Agent'] = @options[:user_agent]
    opts.each { |k, v| req[k] = v if k.is_a?(String) }

    if auth = @options[:basic_auth]
      req.basic_auth(*auth)
    end

    req.body = data ? data : ''

    begin
      Rufus::Jig::HttpResponse.new(@http.request(uri, req))
    rescue Timeout::Error => te
      raise Rufus::Jig::TimeoutError
    end
  end
end


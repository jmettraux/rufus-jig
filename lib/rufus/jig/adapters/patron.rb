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


class Rufus::Jig::HttpResponse

  def initialize (patron_res)

    @original = patron_res
    @status = patron_res.status
    @headers = patron_res.headers
    @body = patron_res.body
  end
end

class Rufus::Jig::Http < Rufus::Jig::HttpCore

  def initialize (*args)

    super(*args)

    @options[:user_agent] ||= "#{self.class} #{Rufus::Jig::VERSION} (patron)"
  end

  def variant
    :patron
  end

  def close

    # nothing to do
  end

  protected

  def get_patron (opts)

    to = (opts[:timeout] || @options[:timeout])
    to = to.to_i if to
    to = nil if to && to < 1

    patron = Patron::Session.new
    patron.base_url = "#{@host}:#{@port}"

    #patron.connect_timeout = 1
      # connection timeout defaults to 1 second
    patron.timeout = to

    patron.headers['User-Agent'] =
      @options[:user_agent] ||
      [ self.class, Rufus::Jig::VERSION, '(patron)' ].join(' ')

    if auth = @options[:basic_auth]
      patron.auth_type = :basic
      patron.username = auth[0]
      patron.password = auth[1]
    end

    patron
  end

  def do_request (method, path, data, opts)

    opts['Expect'] = '' if (method == :put) && ( ! @options[:expect])

    args = case method
      when :post, :put then [ path, data, opts ]
      else [ path, opts ]
    end

    begin
      get_patron(opts).send(method, *args)
    rescue Patron::TimeoutError => te
      raise Rufus::Jig::TimeoutError
    end
  end
end


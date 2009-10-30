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


module Rufus::Couch

  module HttpCommon

    def expand_options (opts)

      opts['Content-Type'] ||= 'application/json'

      opts
    end
  end
end


if defined?(Patron) # gem install patron

  class Rufus::Couch::Http
    include Rufus::Couch::HttpCommon

    def initialize (host, port)

      @patron = Patron.session.new
      @patron.base_url = "#{host}:#{port}"
      @patron.headers['User-Agent'] = "#{self.class} #{Rufus::Couch::VERSION}"
    end

    def get (path, opts={})

      opts = expand_options(opts)

      r = @patron.get(path, opts)

      r.body
    end
  end

elsif defined?(RestClient) # gem install rest_client

  class Rufus::Couch::Http
    include Rufus::Couch::HttpCommon
  end

else

  raise "found no HTTP client, please install gem 'patron' or 'rest_client'"
end


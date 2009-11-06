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


module Rufus::Jig

  #
  # Dealing with multiple JSON libs. Favours yajl-ruby.
  #
  # Lifted from http://github.com/jmettraux/ruote
  #
  module Json

    # The JSON / JSON pure decoder
    #
    JSON = [
      lambda { |o| o.to_json },
      lambda { |s| ::JSON.parse(s) }
    ]

    # The Rails ActiveSupport::JSON decoder
    #
    ACTIVE_SUPPORT = [
      lambda { |o| o.to_json },
      lambda { |s| ActiveSupport::JSON.decode(s) }
    ]

    # http://github.com/brianmario/yajl-ruby/
    #
    YAJL = [
      lambda { |o| Yajl::Encoder.encode(o) },
      lambda { |s| Yajl::Parser.parse(s) }
    ]

    # The "raise an exception because there's no backend" backend
    #
    NONE = [ lambda { |s| raise 'no JSON backend found' } ] * 2

    @backend = if defined?(::Yajl)
      YAJL
    elsif defined?(::JSON)
      JSON
    elsif defined?(ActiveSupport::JSON)
      ACTIVE_SUPPORT
    else
      NONE
    end

    # Forces a decoder JSON/ACTIVE_SUPPORT or any lambda pair that knows
    # how to deal with JSON.
    #
    def self.backend= (b)

      @backend = b
    end

    # Encodes the given object to JSON.
    #
    def self.encode (o)

      @backend[0].call(o)
    end

    # Decodes the given JSON string.
    #
    def self.decode (s)

      @backend[1].call(s)
    end
  end
end


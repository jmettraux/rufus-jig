#--
# Copyright (c) 2009-2010, Kenneth Kalmer and John Mettraux.
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
# Made in South Africa and Japan.
#++


class Rufus::Jig::HttpResponse

  def initialize( em_client )

    @original = [ em_client, em_client.response ]

    @status = em_client.response_header.status
    @headers = response_headers( em_client.response_header )
    @body = em_client.response
  end

  protected

  def response_headers( hash )

    hash.inject({}) do |headers, ( key, value )|
      key = key.downcase.split('_').map { |c| c.capitalize }.join( '-' )
      headers[ key ] = value
      headers
    end
  end
end

class Rufus::Jig::Http < Rufus::Jig::HttpCore

  require 'uri'

  def initialize( *args )

    super( *args )

    @options[:user_agent] ||= "#{self.class} #{Rufus::Jig::VERSION} (em)"
  end

  def variant
    :em
  end

  protected

  def do_request( method, path, data, opts )

    args = {}

    args[:head] = request_headers( opts )
    args[:body] = data if data

    if to = (opts[:timeout] || @options[:timeout])
      to = to.to_f
      args[:timeout] = (to < 1.0) ? (3 * 24 * 3600).to_f : to
    else
      args[:timeout] = 5.0 # like Patron
    end

    if auth = @options[:basic_auth]
      args[:head].merge!( 'authorization' => auth )
    end

    em_response( em_request( path ).send( method, args ) )
  end

  def em_request( uri = '/' )

    uri = Rufus::Jig.parse_uri( uri )
    uri = URI::HTTP.build(
      :host => uri.host || @host,
      :port => uri.port || @port,
      :path => uri.path,
      :query => uri.query
    )

    EventMachine::HttpRequest.new( uri.to_s )
  end

  def em_response( em_client )

    th = Thread.current

    timedout = false

    em_client.errback {

      #th.raise( Rufus::Jig::TimeoutError.new )
        # works with ruby < 1.9.x
      th.wakeup
    }

    em_client.callback {
      th.wakeup
    }

    Thread.stop

    # after the wake up...

    raise Rufus::Jig::TimeoutError if em_client.response_header.status == 0

    Rufus::Jig::HttpResponse.new( em_client )
  end

  def request_headers( options )

    headers = { 'user-agent' => @options[:user_agent] }

    %w[ Accept If-None-Match Content-Type ].each do |k|
      headers[k] = options[k] if options.has_key?( k )
    end

    headers
  end
end


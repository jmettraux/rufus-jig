require 'typhoeus'

class Rufus::Jig::HttpResponse

  def initialize(response)

    @original = response

    @status  = response.code
    @headers = response.headers_hash
    @body    = response.body
  end

end

class Rufus::Jig::Http < Rufus::Jig::HttpCore

  def initialize(*args)

    super(*args)

    @options[:user_agent] ||= "#{self.class} #{Rufus::Jig::VERSION} (typhoeus)"
  end

  def variant

    :typhoeus
  end

  def close

    # nothing to do
  end

  protected

  def do_request(method, path, data, opts)

    host = "#@host:#@port#{path}"

    headers = (@headers || {}).merge('User-Agent' => @options[:user_agent])
    opts.each { |k, v| headers[k] = v if k.is_a?(String) }

    options = {
      :method  => method.to_sym,
      :body    => (data || ''),
      :headers => headers
    }

    if @options[:basic_auth]
      options[:userpwd] = @options[:basic_auth].join(':')
    end

    if to = (opts[:timeout] || @options[:timeout])
      options[:timeout] = to.to_i
    else
      options[:timeout] = 5
    end

    response = Typhoeus::Request.new(host, options).run
    if response.timed_out?
      raise Rufus::Jig::TimeoutError
    else
      Rufus::Jig::HttpResponse.new(response)
    end
  end
end

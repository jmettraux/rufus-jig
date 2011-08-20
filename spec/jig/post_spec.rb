
#
# specifiying rufus-jig
#
# Tue Nov 30 21:09:24 JST 2010
#

require File.expand_path('../../spec_helper.rb', __FILE__)


describe Rufus::Jig::Http do

  before(:each) do
    purge_server
    @h = Rufus::Jig::Http.new('127.0.0.1', 4567)
  end
  after(:each) do
    @h.close
  end

  def location
    l = @h.last_response.headers['Location']
    l.match(/^http:\/\//) ? l = '/' + l.split('/')[3..-1].join('/') : l
  end

  describe '#post' do

    it 'returns the body of the server response' do

      @h.post('/documents', 'nada').should == 'created.'
    end

    it 'encodes hashes as JSON by default' do

      @h.post('/documents', { 'hello' => 'world' })

      @h.get(location, :accept => :json).should == { 'hello' => 'world' }
    end

    it 'encodes arrays as JSON by default' do

      @h.post('/documents', %w[ a b c ])

      @h.get(location, :accept => :json).should == %w[ a b c ]
    end

    it 'passes strings as text/plain by default' do

      @h.post('/documents', 'nada')

      @h.get(location, :accept => :json).should == 'nada'
    end

    it 'decodes the body of the server response' do

      b = @h.post(
        '/documents?mirror=true',
        '{"msg":"hello world"}',
        :content_type => :json)

      b.should == { 'msg' => 'hello world' }
    end

    it "by default, doesn't cache" do

      @h.post('/documents?etag=true', 'nada')

      @h.cache.size.should == 0
    end

    it 'caches when :cache => true' do

      @h.post('/documents?etag=true', 'nada', :cache => true)

      @h.cache.size.should == 1
    end
  end
end



#
# specifiying rufus-jig
#
# Wed Dec  1 09:12:40 JST 2010
#

require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')


describe Rufus::Jig do

  before(:each) do
    purge_server
    @h = Rufus::Jig::Http.new('127.0.0.1', 4567)
  end
  after(:each) do
    @h.close
  end

  describe '#put' do

    it "puts" do

      @h.put(
        '/documents/1234',
        '{"msg":"hello"}',
        :content_type => 'application/json')

      @h.get('/documents/1234').should == { 'msg' => 'hello' }
    end

    it 'puts and decodes the JSON reply' do

      b = @h.put(
        '/documents/yyyy?mirror=true',
        '{"msg":"hello world"}',
        :content_type => :json)

      b.should == { 'msg' => 'hello world' }
    end

    it 'returns true in case of conflict' do

      @h.put('/conflict', '').should == true
    end

    it "by default, doesn't cache" do

      @h.put(
        '/documents/1234',
        '{"msg":"hello"}',
        :content_type => 'application/json')

      @h.cache.size.should == 0
    end

    it 'caches when :cache => true' do

      @h.put(
        '/documents/yyyy?etag=true',
        '{"msg":"hello world"}', :cache => true)

      @h.cache.size.should == 1
    end
  end
end



#
# specifiying rufus-jig
#
# Tue Nov 30 13:03:00 JST 2010
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

  context 'with conditional requests' do

    describe '#get' do

      it "caches the response" do

        @h.get('/document_with_etag')

        @h.cache.should == {
          '/document_with_etag' => [ '"123456123456"', { 'car' => 'Peugeot' } ]
        }
      end

      it "goes 200 then 304" do

        @h.get('/document_with_etag', :raw => true).status.should == 200
        @h.get('/document_with_etag', :raw => true).status.should == 304
      end

      it "doesn't cache when :cache => false" do

        @h.get('/document_with_etag', :cache => false)

        @h.cache.should == {}
      end

      it "returns duplicates" do

        doc0 = @h.get('/document_with_etag', :raw => true)
        doc1 = @h.get('/document_with_etag', :raw => true)

        doc0.object_id.should_not == doc1.object_id
      end

      it "goes 200 when the ETag is obsolete" do

        @h.get('/document_with_etag')
        @h.get('/document_with_etag', :etag => '"nada"')

        @h.last_response.status.should == 200
      end
    end

    describe '#cache' do

      it 'should be clearable' do

        @h.get('/document_with_etag')
        @h.cache.clear

        @h.cache.size.should == 0
      end
    end
  end
end


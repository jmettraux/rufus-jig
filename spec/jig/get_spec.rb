# encoding: utf-8

#
# specifiying rufus-jig
#
# Tue Nov 30 10:53:59 JST 2010
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

  describe '.new' do

    after(:each) do
      @http.close rescue nil
    end

    it 'connects to the server' do

      @http = Rufus::Jig::Http.new('127.0.0.1', 4567)

      @h._path.should == ''
      lambda { @h.get('/') }.should_not raise_error
    end
  end

  describe '#get' do

    context 'by default' do

      it 'decodes from JSON' do

        @h.get('/document').should == { 'car' => 'Mercedes-Benz' }
      end

      it 'returns nil in case of 404' do

        @h.get('/nada').should == nil
      end

      it 'raises an error in case of server error' do

        lambda {
          @h.get('/server_error')
        }.should raise_error(Rufus::Jig::HttpError)
      end

      it 'is OK with a non-ASCII URI' do

        @h.get('/川崎').should == nil
      end
    end

    context 'with :raw => true' do

      it 'returns an HTTP response instance' do

        r = @h.get('/document', :raw => true)

        r.status.should == 200
        r.body.should == "{\"car\":\"Mercedes-Benz\"}"
      end

      it "doesn't raise an error in case of server error" do

        lambda {
          @h.get('/server_error', :raw => true)
        }.should_not raise_error
      end
    end

    context 'with :accept => mime_type' do

      it "returns the text/plain" do

        @h.get('/document_accept', :accept => 'text/plain').should ==
          '{"car":"Saab"}'
      end

      it "returns the application/json" do

        @h.get('/document_accept', :accept => 'application/json').should == {
           "car" => "Saab" }
      end

      it "returns JSON when :accept => :json" do

        @h.get('/document_accept', :accept => :json).should == {
           "car" => "Saab" }
      end
    end

    context 'with :force_json => true' do

      it "returns JSON anyway" do

        @h.get('/document_accept', :accept => :json).should == {
           "car" => "Saab" }

        @h.get('/document_json_plain', :force_json => true).should == {
           "car" => "Peugeot" }
      end
    end
  end
end


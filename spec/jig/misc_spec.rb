
#
# specifiying rufus-jig
#
# Tue Nov 30 15:13:43 JST 2010
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

  context 'with parameters' do

    describe '#get and co' do

      it 'accepts get("/params")' do

        @h.get('/params').should == {}
      end

      it 'accepts get("/params?a=b")' do

        @h.get('/params?a=b').should == {
          'a' => 'b' }
      end

      it 'accepts get("/params", :params => { "a" => "b" })' do

        @h.get('/params', :params => { "a" => "b" }).should == {
          'a' => 'b' }
      end

      it 'accepts get("/params?a=b", :params => { "c" => "d" })' do

        @h.get('/params?a=b', :params => { "c" => "d" }).should == {
          'a' => 'b', 'c' => 'd' }
      end
    end
  end
end


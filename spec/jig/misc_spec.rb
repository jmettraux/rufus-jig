
#
# specifiying rufus-jig
#
# Tue Nov 30 15:13:43 JST 2010
#

require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')


describe Rufus::Jig::Http do

  after(:each) do
    @h.close
  end

  context 'with parameters' do

    before(:each) do
      purge_server
      @h = Rufus::Jig::Http.new('127.0.0.1', 4567)
    end

    describe '#get and co' do

      it 'accepts get("/params")' do

        @h.get('/params').should == {
          }
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

  context 'absolute vs relative' do

    describe '#get and co' do

      context 'without a :prefix' do

        before(:each) do
          purge_server
          @h = Rufus::Jig::Http.new('127.0.0.1', 4567)
        end

        it 'gets the right thing' do

          @h.get('a/b/c').should == 'C'
          @h.get('/a/b/c').should == 'C'
        end
      end

      context 'with :prefix => ""' do

        before(:each) do
          purge_server
          @h = Rufus::Jig::Http.new('127.0.0.1', 4567, :prefix => 'a/b')
        end

        it 'gets the right thing' do

          @h.get('a/b/c').should == nil
          @h.get('/a/b/c').should == 'C'
        end
      end

      context 'with :prefix => "a/b"' do

        before(:each) do
          purge_server
          @h = Rufus::Jig::Http.new('127.0.0.1', 4567, :prefix => 'a/b')
        end

        it 'gets the right thing' do

          @h.get('c').should == 'C'
          @h.get('/c').should == 'c'
        end
      end

      context 'with :prefix => "/a/b"' do

        before(:each) do
          purge_server
          @h = Rufus::Jig::Http.new('127.0.0.1', 4567, :prefix => '/a/b')
        end

        it 'gets the right thing' do

          @h.get('c').should == 'C'
          @h.get('/c').should == 'c'
        end

        it 'gets the right document' do

          @h.get('document').should == nil
          @h.get('/document').should == { 'car' => 'Mercedes-Benz' }
        end
      end
    end
  end
end


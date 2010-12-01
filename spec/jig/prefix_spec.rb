
#
# specifiying rufus-jig
#
# Wed Dec  1 09:36:50 JST 2010
#

require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')


describe Rufus::Jig::Http do

  before(:each) do
    purge_server
    @h = Rufus::Jig::Http.new('127.0.0.1', 4567, :prefix => '/a/b/')
  end
  after(:each) do
    @h.close
  end

  context "with :prefix => '/a/b'" do

    it 'gets' do

      @h.get('c').should == 'C'
    end

    it 'caches the full path' do

      @h.get('c')

      @h.cache.should == { '/a/b/c' => [ '"123456123456"', 'C' ] }
    end

    it 'posts' do

      @h.post('c', 'X').should == 'post'
    end

    it 'puts' do

      @h.put('c', 'X').should == 'put'
    end

    it 'deletes' do

      @h.delete('c').should == 'delete'
    end
  end
end



#
# specifiying rufus-jig
#
# Wed Dec  1 09:12:25 JST 2010
#

require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')


describe Rufus::Jig::Http do

  before(:each) do
    purge_server
    @h = Rufus::Jig::Http.new('127.0.0.1', 4567)
    @h.put('/documents/xyz', 'data', :content_type => 'text/plain', :raw => true)
  end
  after(:each) do
    @h.close
  end

  describe '#delete' do

    it 'deletes' do

      @h.delete('/documents/xyz')

      @h.get('/documents/xyz').should == nil
    end
  end
end


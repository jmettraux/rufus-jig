
#
# specifiying rufus-jig
#
# Wed Dec  1 15:07:42 JST 2010
#

require File.expand_path('../../spec_helper.rb', __FILE__)


describe Rufus::Jig::Http do

  context 'HTTP basic authorization' do

    context 'without authorization' do

      before(:each) do
        purge_server
        @h = Rufus::Jig::Http.new('127.0.0.1', 4567)
      end
      after(:each) do
        @h.close
      end

      it 'gets denied' do

        lambda {
          @h.get('/protected')
        }.should raise_error(Rufus::Jig::HttpError)
      end
    end

    context 'with authorization' do

      before(:each) do
        purge_server
        @h = Rufus::Jig::Http.new(
          '127.0.0.1', 4567, :basic_auth => %w[ admin nimda ])
      end
      after(:each) do
        @h.close
      end

      it 'gets through' do

        @h.get('/protected').should == { 'info' => 'secretive' }
      end
    end
  end
end


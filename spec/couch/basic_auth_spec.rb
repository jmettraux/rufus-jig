
#
# specifying rufus-jig
#
# Wed Dec  1 15:16:31 JST 2010
#

require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')


describe Rufus::Jig::Couch do

  after(:each) do

    @c.close
  end

  context 'HTTP basic authorization' do

    context 'without authorization' do

      before(:each) do

        @c = Rufus::Jig::Couch.new('127.0.0.1', 4567, 'tcouch')
      end

      it 'gets denied' do

        lambda {
          @c.get('.')
        }.should raise_error(Rufus::Jig::HttpError)
      end

      it 'cannot do #on_change' do

        lambda {
          @c.on_change do |id, deleted, doc|
          end
        }.should raise_error(Rufus::Jig::HttpError)
      end
    end

    context 'with authorization' do

      before(:each) do

        @c = Rufus::Jig::Couch.new(
          '127.0.0.1', 4567, 'tcouch', :basic_auth => %w[ admin nimda ])
      end

      it 'gets through' do

        @c.get('.').should == { 'id' => 'nada' }
      end

      it 'can do #on_change' do

        res = nil

        t = Thread.new {
          @c.on_change do |id, deleted, doc|
            res = [ id, deleted, doc ]
          end
        }

        sleep 0.200

        t.kill

        res.should == [ 'x', false, { 'hello' => 'world' } ]
      end
    end
  end
end



#
# specifying rufus-jig
#
# Mon Nov 29 22:14:22 JST 2010
#

require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')


describe Rufus::Jig::Couch do

  context 'without a particular db' do

    before(:each) do

      h = Rufus::Jig::Http.new(couch_url)
      begin
        h.delete('/rufus_jig_test')
      rescue Exception => e
        #p e
      ensure
        h.close rescue nil
      end

      @c = Rufus::Jig::Couch.new(couch_url)
    end

    after(:each) do

      @c.close
    end

    describe '#get' do

      it 'returns a Hash instance' do

        @c.get('.').keys.sort.should == %w[ couchdb version ]
      end
    end

    describe '#put' do

      it 'can put a db' do

        @c.put('rufus_jig_test')

        Rufus::Jig::Http.new(couch_url).get('/rufus_jig_test').should_not == nil
      end
    end

    describe '#delete' do

      it 'can delete a db' do

        @c.put('rufus_jig_test')
        @c.delete('rufus_jig_test')

        Rufus::Jig::Http.new(couch_url).get('/rufus_jig_test').should == nil
      end
    end
  end
end


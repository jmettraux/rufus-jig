# encoding: utf-8

#
# specifying rufus-jig
#
# Mon Nov 29 22:45:31 JST 2010
#

require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')


describe Rufus::Jig::Couch do

  context 'with a db' do

    before(:each) do

      h = Rufus::Jig::Http.new(couch_url)

      begin
        h.delete('/rufus_jig_test')
      rescue Exception => e
        #p e
      end

      h.put('/rufus_jig_test', '')
      h.put('/rufus_jig_test/coffee1', '{"_id":"coffee1","type":"ristretto"}')

      h.close

      @c = Rufus::Jig::Couch.new(couch_url, 'rufus_jig_test')
      @doc = @c.get('coffee1')
    end

    after(:each) do

      @c.close
    end

    describe '#path' do

      it "returns the path for this couch db" do

        @c.path.should == 'rufus_jig_test'
      end
    end

    describe '#name' do

      it "returns the name of this couch db" do

        @c.name.should == 'rufus_jig_test'
      end
    end

    describe '#get' do

      it "returns nil when the doc doesn't exist" do

        @c.get('coffee-1').should == nil
      end

      it "returns the doc when it exists" do

        @c.get('coffee1')['type'].should == 'ristretto'
      end

      it 'can get docs with UTF-8 ids' do

        @c.put('_id' => 'コーヒー', 'type' => 'espresso')

        @c.get('コーヒー')['type'].should == 'espresso'
      end
    end

    describe '#delete(doc)' do

      it 'deletes a document' do

        @c.delete(@doc)

        @c.get('coffee1').should == nil
      end

      it "returns nil when it's successful" do

        @c.delete(@doc).should == nil
      end

      it "returns the current doc when the delete's rev is wrong" do

        @doc['_rev'] = "777-12er"

        @c.delete(@doc)['type'].should == 'ristretto'
      end

      it "returns true when the doc is already gone" do

        @c.delete(@doc)

        @c.delete(@doc).should == true
      end
    end

    describe '#delete(id, rev)' do

      it 'deletes a document' do

        @c.delete(@doc['_id'], @doc['_rev'])

        @c.get('coffee1').should == nil
      end

      it 'returns nil when successful' do

        @c.delete(@doc['_id'], @doc['_rev']).should == nil
      end

      it 'returns the current doc if the rev is outdated' do

        @c.delete(@doc['_id'], '999-2')['type'].should == 'ristretto'
      end

      it 'returns true if the doc is already gone' do

        @c.delete(@doc)

        @c.delete(@doc['_id'], @doc['_rev']).should == true
      end
    end

    describe '#put' do

      it 'returns nil when the put was successful' do

        @c.put({ '_id' => 'coffee0', 'type' => 'espresso' }).should == nil
      end

      it 'returns the current doc if the put has the wrong _rev' do

        @c.put({ '_id' => 'coffee1', 'type' => 'espresso' })['type'].should ==
          'ristretto'
      end

      it 'returns true when putting a doc that is gone' do

        @c.delete(@doc)

        @c.put(@doc).should == true
      end

      it 'updates the _rev of the doc when :update_rev => true' do

        rev = @doc['_rev']
        @c.put(@doc, :update_rev => true)

        @doc['_rev'].should_not == rev
      end

      it 'returns true when putting a doc in a missing db' do

        @c.delete('.')

        @c.put({ '_id' => 'coffee0', 'type' => 'espresso' }).should == true
      end

      it 'can put UTF-8 stuff' do

        @c.put('_id' => 'コーヒー', 'type' => 'espresso').should == nil
      end
    end
  end
end


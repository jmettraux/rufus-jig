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
      @doc = @c.get('coffee1', :cache => false)
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

      it 'caches documents' do

        @c.get('coffee1')
        @c.http.cache.size.should == 1
      end

      it 'goes 200 then 304' do

        @c.get('coffee1')
        @c.http.last_response.status.should == 200

        @c.get('coffee1')
        @c.http.last_response.status.should == 304
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

    describe '#all' do

      before(:each) do

        @c.put({
          '_id' => '_design/my_test',
          'views' => {
            'my_view' => {
              'map' => "function(doc) { emit(doc['type'], null); }"
            }
          }
        })

        3.times { |i| @c.put({ '_id' => "tea#{i}" }) }
      end

      it 'gets many docs at once' do

        docs = @c.all

        docs.collect { |doc| doc['_id'] }.should == %w[
          _design/my_test coffee1 tea0 tea1 tea2
        ]
      end

      it 'accepts parameters like :limit' do

        docs = @c.all(:skip => 2, :limit => 1)

        docs.collect { |doc| doc.delete('_rev'); doc }.should == [
          { '_id' => 'tea0' }
        ]
      end

      it 'accepts the :keys parameters' do

        docs = @c.all(:keys => %w[ tea1 tea2 ])

        docs.collect { |doc| doc.delete('_rev'); doc }.should == [
          { '_id' => 'tea1' }, { '_id' => 'tea2' }
        ]
      end

      it 'returns immediately [] if :keys => []' do

        lroi = @c.http.last_response.object_id
        docs = @c.all(:keys => [])

        docs.should == []
        @c.http.last_response.object_id.should == lroi
      end

      it 'accepts :include_docs => false' do

        docs = @c.all(:include_docs => false)

        docs.size.should == 5

        docs.inject([]) { |a, doc| a.concat(doc.keys) }.uniq.sort.should ==
          %w[ _id _rev ]
      end

      it "doesn't list design docs when :include_design_docs => false" do

        @c.all(
          :include_design_docs => false
        ).collect { |d|
          d['_id']
        }.should == %w[
          coffee1 tea0 tea1 tea2
        ]
      end

      it 'is OK with nil parameters' do

        docs = @c.all(:skip => 3, :limit => nil)

        docs.collect { |doc| doc['_id'] }.should == %w[ tea1 tea2 ]
      end

      it 'leaves the opts hash untouched' do

        opts = { :skip => 3, :limit => nil }

        @c.all(opts)

        opts.should == { :skip => 3, :limit => nil }
      end
    end

    describe '#ids' do

      before(:each) do
        @c.put({
          '_id' => '_design/my_test',
          'views' => {
            'my_view' => {
              'map' => "function(doc) { emit(doc['type'], null); }"
            }
          }
        })
      end

      it 'list all ids' do

        @c.ids.should == %w[ _design/my_test coffee1 ]
      end

      it 'list all ids but :include_design_docs => false' do

        @c.ids(:include_design_docs => false).should == %w[ coffee1 ]
      end
    end

    describe '#bulk_put' do

      it 'creates many docs at once' do

        @c.bulk_put([
          { '_id' => 'h0', 'msg' => 'ok' },
          { '_id' => 'h1', 'msg' => 'not ok' }
        ])

        @c.ids.should == %w[ coffee1 h0 h1 ]
      end

      it "returns a list [ { '_id' => x, '_rev' => y } ]" do

        res = @c.bulk_put([
          { '_id' => 'h2', 'msg' => 'ok' },
          { '_id' => 'h3', 'msg' => 'not ok' }
        ])

        res.collect { |row| row['_id'] }.should == %w[ h2 h3 ]
        res.collect { |row| row.keys }.flatten.uniq.should == %w[ _id _rev ]
      end
    end

    describe '#bulk_delete' do

      before(:each) do
        3.times { |i| @c.put({ '_id' => "macha#{i}" }) }
      end

      it 'deletes in bulk' do

        docs = @c.all(:keys => %w[ coffee1 macha1 ])

        @c.bulk_delete(docs)

        @c.ids.should == %w[ macha0 macha2 ]
      end

      it 'is OK with nil docs' do

        docs = @c.all(:keys => %w[ nada macha1 ])

        @c.bulk_delete(docs)

        @c.ids.should == %w[ coffee1 macha0 macha2 ]
      end

      it 'returns the list of deleted docs' do

        docs = @c.all(:keys => %w[ nada macha1 ])

        res = @c.bulk_delete(docs)

        res.collect { |doc| doc['_id'] }.should == %w[ macha1 ]

        res.first['_rev'].should match(/^2-/)
          # does it deserve its own spec ?
      end
    end
  end
end


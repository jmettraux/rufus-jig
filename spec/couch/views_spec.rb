
#
# specifying rufus-jig
#
# Tue Nov 30 08:40:05 JST 2010
#

require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')


describe Rufus::Jig::Couch do

  context 'with views' do

    before(:each) do

      h = Rufus::Jig::Http.new(couch_url)

      begin
        h.delete('/rufus_jig_test')
      rescue Exception => e
        #p e
      end

      h.put('/rufus_jig_test', '')

      h.put('/rufus_jig_test/c0', '{"_id":"c0","type":"espresso"}')
      h.put('/rufus_jig_test/c1', '{"_id":"c1","type":"ristretto"}')
      h.put('/rufus_jig_test/c2', '{"_id":"c2","type":"macchiato"}')
      h.put('/rufus_jig_test/c3', '{"_id":"c3","type":"capuccino"}')
      h.put('/rufus_jig_test/c4', '{"_id":"c4","type":"macchiato"}')
      h.put('/rufus_jig_test/c5', '{"_id":"c5","type":"veloce espresso"}')

      h.put(
        '/rufus_jig_test/_design/my_test',
        {
          '_id' => '_design/my_test',
          'views' => {
            'my_view' => {
              'map' => "function(doc) { emit(doc['type'], null); }"
            },
            'my_reduced_view' => {
              'map' => "function(doc) { emit(doc['type'], 1); }",
              'reduce' => "_count"
            }
          }
        },
        :content_type => :json)

      h.close

      @c = Rufus::Jig::Couch.new(couch_url, 'rufus_jig_test')
    end

    after(:each) do

      @c.close
    end

    describe '#get from view' do

      it 'returns the result set' do

        @c.get('_design/my_test/_view/my_view').should == {
          "total_rows"=>6,
          "offset"=>0,
          "rows"=> [
            {"id"=>"c3", "key"=>"capuccino", "value"=>nil},
            {"id"=>"c0", "key"=>"espresso", "value"=>nil},
            {"id"=>"c2", "key"=>"macchiato", "value"=>nil},
            {"id"=>"c4", "key"=>"macchiato", "value"=>nil},
            {"id"=>"c1", "key"=>"ristretto", "value"=>nil},
            {"id"=>"c5", "key"=>"veloce espresso", "value"=>nil}
          ]
        }
      end
    end

    describe '#post keys to view' do

      it 'returns the desired docs' do

        @c.post(
          '_design/my_test/_view/my_view',
          { 'keys' => [ 'espresso', 'macchiato' ] }
        ).should == {
          "total_rows"=>6,
          "offset"=>1,
          "rows"=> [
            {"id"=>"c0", "key"=>"espresso", "value"=>nil},
            {"id"=>"c2", "key"=>"macchiato", "value"=>nil},
            {"id"=>"c4", "key"=>"macchiato", "value"=>nil}
          ]
        }
      end

      it 'returns no row when the key points to nothing' do

        @c.post(
          '_design/my_test/_view/my_view',
          { 'keys' => [ 'espresso', 'macha' ] }
        ).should == {
          "total_rows"=>6,
          "offset"=>1,
          "rows"=> [
            {"id"=>"c0", "key"=>"espresso", "value"=>nil}
          ]
        }
      end
    end

    describe '#nuke_design_documents' do

      it 'removes design documents from the db' do

        @c.nuke_design_documents

        @c.get('_design/my_test').should == nil
      end
    end

    describe '#query' do

      it 'queries with the full path (_design/<id>/_view/<view>' do

        @c.query('_design/my_test/_view/my_view').should == [
          {"id"=>"c3", "key"=>"capuccino", "value"=>nil},
          {"id"=>"c0", "key"=>"espresso", "value"=>nil},
          {"id"=>"c2", "key"=>"macchiato", "value"=>nil},
          {"id"=>"c4", "key"=>"macchiato", "value"=>nil},
          {"id"=>"c1", "key"=>"ristretto", "value"=>nil},
          {"id"=>"c5", "key"=>"veloce espresso", "value"=>nil}
        ]
      end

      it 'queries with the short path (<id>:<view>)' do

        @c.query('my_test:my_view').should == [
          {"id"=>"c3", "key"=>"capuccino", "value"=>nil},
          {"id"=>"c0", "key"=>"espresso", "value"=>nil},
          {"id"=>"c2", "key"=>"macchiato", "value"=>nil},
          {"id"=>"c4", "key"=>"macchiato", "value"=>nil},
          {"id"=>"c1", "key"=>"ristretto", "value"=>nil},
          {"id"=>"c5", "key"=>"veloce espresso", "value"=>nil}
        ]
      end

      it 'returns the complete response on :raw => true' do

        @c.query('my_test:my_view', :raw => true).should == {
          "total_rows"=>6,
          "offset"=>0,
          "rows"=>
           [{"id"=>"c3", "key"=>"capuccino", "value"=>nil},
            {"id"=>"c0", "key"=>"espresso", "value"=>nil},
            {"id"=>"c2", "key"=>"macchiato", "value"=>nil},
            {"id"=>"c4", "key"=>"macchiato", "value"=>nil},
            {"id"=>"c1", "key"=>"ristretto", "value"=>nil},
            {"id"=>"c5", "key"=>"veloce espresso", "value"=>nil}]
        }
      end

      it 'accepts parameters' do

        @c.query('my_test:my_view', :limit => 2).should == [
          {"id"=>"c3", "key"=>"capuccino", "value"=>nil},
          {"id"=>"c0", "key"=>"espresso", "value"=>nil}
        ]
      end

      it 'is OK with reduced views' do

        @c.query('my_test:my_reduced_view', :group => true).should == [
          {"key"=>"capuccino", "value"=>1},
          {"key"=>"espresso", "value"=>1},
          {"key"=>"macchiato", "value"=>2},
          {"key"=>"ristretto", "value"=>1},
          {"key"=>"veloce espresso", "value"=>1}
        ]
      end

      it 'is OK with reduced views and :key' do

        @c.query(
          'my_test:my_reduced_view', :key => 'macchiato', :group => true
        ).should == [
          { 'key' => 'macchiato', 'value' => 2 }
        ]
      end

      it 'is OK with complex keys (array for example' do

        lambda {
          @c.query(
            'my_test:my_reduced_view', :key => [ "a", 2 ], :group => true)
        }.should_not raise_error
      end

      it 'uses POST when there is a :keys parameter' do

        @c.query(
          'my_test:my_view', :keys => %w[ capuccino ristretto ]
        ).should == [
          {"id"=>"c3", "key"=>"capuccino", "value"=>nil},
          {"id"=>"c1", "key"=>"ristretto", "value"=>nil}
        ]
      end

      it 'caches in case of GET' do

        @c.query('my_test:my_view')
        s0 = @c.http.last_response.status
        @c.query('my_test:my_view')
        s1 = @c.http.last_response.status

        s0.should == 200
        s1.should == 304
        @c.http.cache.size.should == 1
      end

      it 'caches in case of POST' do

        @c.query('my_test:my_view', :keys => %w[ capuccino ristretto ])
        s0 = @c.http.last_response.status
        @c.query('my_test:my_view', :keys => %w[ capuccino ristretto ])
        s1 = @c.http.last_response.status

        s0.should == 200
        s1.should == 304
        @c.http.cache.size.should == 1
      end

      it 'does not cache if :cache => false (GET)' do

        @c.query('my_test:my_view', :cache => false)

        @c.http.cache.size.should == 0
      end

      it 'does not cache if :cache => false (POST)' do

        @c.query(
          'my_test:my_view',
          :keys => %w[ capuccino ristretto ], :cache => false)

        @c.http.cache.size.should == 0
      end

      it 'escapes :key(s) in the URI' do

        @c.query('my_test:my_view', :key => 'veloce espresso').should == [
          { 'id' => 'c5', 'key' => 'veloce espresso', 'value' => nil }
        ]
      end
    end

    describe '#query_for_docs' do

      it 'returns documents' do

        docs = @c.query_for_docs('my_test:my_view')

        docs.collect { |doc| doc['type'] }.should == %w[
          capuccino espresso macchiato macchiato ristretto
        ] + [ 'veloce espresso' ]
      end

      it 'accepts :keys' do

        docs = @c.query_for_docs('my_test:my_view', :keys => %w[ macchiato ])

        docs.collect { |doc| doc['_id'] }.should == %w[ c2 c4 ]
      end
    end

    describe '#all' do

      it 'includes design docs by default' do

        @c.all.map { |d| d['_id'] }.should == %w[
          _design/my_test c0 c1 c2 c3 c4 c5
        ]
      end

      it 'does not list design docs if :include_design_docs => false' do

        @c.all(:include_design_docs => false).map { |d| d['_id'] }.should == %w[
          c0 c1 c2 c3 c4 c5
        ]
      end

      it 'does not list design doc ids when :include_docs => false' do

        res = @c.all(:include_design_docs => false, :include_docs => false)

        res.inject([]) { |a, row| a.concat(row.keys) }.uniq.sort.should ==
          %w[ _id _rev ]

        res.collect { |row| row['_id'] }.should_not include('_design/my_test')
      end

      it 'returns only the requested docs when passed a set of :keys' do

        @c.all(:keys => %w[ c2 c3 ]).map { |d| d['_id'] }.should == [
          'c2', 'c3'
        ]
      end
    end
  end
end


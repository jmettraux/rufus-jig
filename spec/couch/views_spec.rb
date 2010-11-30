
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

      h.put(
        '/rufus_jig_test/_design/my_test',
        {
          '_id' => '_design/my_test',
          'views' => {
            'my_view' => {
              'map' => "function (doc) { emit(doc['type'], null); }"
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
          "total_rows"=>5,
          "offset"=>0,
          "rows"=> [
            {"id"=>"c3", "key"=>"capuccino", "value"=>nil},
            {"id"=>"c0", "key"=>"espresso", "value"=>nil},
            {"id"=>"c2", "key"=>"macchiato", "value"=>nil},
            {"id"=>"c4", "key"=>"macchiato", "value"=>nil},
            {"id"=>"c1", "key"=>"ristretto", "value"=>nil}
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
          "total_rows"=>5,
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
          "total_rows"=>5,
          "offset"=>1,
          "rows"=> [
            {"id"=>"c0", "key"=>"espresso", "value"=>nil}
          ]
        }
      end
    end

    describe '#query' do

      it 'flips burgers'
    end

    describe '#nuke_design_documents' do

      it 'removes design documents from the db' do

        @c.nuke_design_documents

        @c.get('_design/my_test').should == nil
      end
    end
  end
end


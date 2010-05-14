
#
# testing rufus-jig
#
# Fri Feb 12 13:17:18 JST 2010
#

require File.join(File.dirname(__FILE__), 'couch_base')


class CtCouchDbViewsTest < Test::Unit::TestCase

  def setup

    h = Rufus::Jig::Http.new('127.0.0.1', 5984)

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

    @c = Rufus::Jig::Couch.new('127.0.0.1', 5984, 'rufus_jig_test')
  end

  def teardown

    @c.close
  end

  def test_get

    #"_design/ruote/_view/by_wfid?key=%22#{m[1]}%22" +

    #p @c.get('_design/my_test/_view/my_view?limit=2')
    assert_equal(
      {"total_rows"=>5, "rows"=>[{"id"=>"c3", "value"=>nil, "key"=>"capuccino"}, {"id"=>"c0", "value"=>nil, "key"=>"espresso"}], "offset"=>0},
      @c.get('_design/my_test/_view/my_view?limit=2'))
  end

  def test_get_key

    #p @c.get('_design/my_test/_view/my_view?key=%22macchiato%22')
    assert_equal(
      {"total_rows"=>5, "rows"=>[{"id"=>"c2", "value"=>nil, "key"=>"macchiato"}, {"id"=>"c4", "value"=>nil, "key"=>"macchiato"}], "offset"=>2},
      @c.get('_design/my_test/_view/my_view?key=%22macchiato%22'))
  end

  def test_post_keys

    #p @c.post('_design/my_test/_view/my_view', { 'keys' => [ 'espresso', 'macchiato' ] })
    assert_equal(
      {"total_rows"=>5, "rows"=>[{"id"=>"c0", "value"=>nil, "key"=>"espresso"}, {"id"=>"c2", "value"=>nil, "key"=>"macchiato"}, {"id"=>"c4", "value"=>nil, "key"=>"macchiato"}], "offset"=>1},
      @c.post('_design/my_test/_view/my_view', { 'keys' => [ 'espresso', 'macchiato' ] }))
  end

  #def test_put_views
  #  p @c.get('_design/my_test_2')
  #  @c.put(
  #    {
  #      '_id' => '_design/my_test_2',
  #      'views' => {
  #        'my_view' => {
  #          'map' => "function (doc) { emit(doc['type'], null); }"
  #        }
  #      }
  #    })
  #  p @c.http.cache.keys
  #  p @c.get('_design/my_test_2/_view/my_view?key=%22macchiato%22')
  #  p @c.http.cache.keys
  #  p @c.get('_design/my_test_2/_view/my_view?key=%22macchiato%22')
  #  p @c.http.cache.keys
  #end

  def test_nuke_design_documents

    assert_not_nil @c.get('_design/my_test')

    @c.nuke_design_documents

    assert_nil @c.get('_design/my_test')
  end
end



#
# testing rufus-jig
#
# Sun Dec 13 15:03:36 JST 2009
#

require File.join(File.dirname(__FILE__), 'couch_base')


class CtCouchDbTest < Test::Unit::TestCase

  def setup

    h = Rufus::Jig::Http.new('127.0.0.1', 5984)

    begin
      h.delete('/rufus_jig_test')
    rescue Exception => e
      #p e
    end

    h.put('/rufus_jig_test', '')
    h.put('/rufus_jig_test/coffee1', '{"_id":"coffee1","type":"ristretto"}')

    h.close

    @c = Rufus::Jig::Couch.new('127.0.0.1', 5984, 'rufus_jig_test')
  end

  def teardown

    @c.close
  end

  def test_put

    r = @c.put('_id' => 'coffee0', 'type' => 'espresso')

    assert_nil r

    doc = Rufus::Jig::Http.new('127.0.0.1', 5984).get('/rufus_jig_test/coffee0')

    assert_not_nil doc['_rev']
  end

  def test_put_fail

    r = @c.put('_id' => 'coffee1', 'type' => 'espresso')

    assert_equal true, r
  end

  def test_put_conflict

    r = @c.put(
      '_id' => 'coffee1',
      'type' => 'espresso',
      '_rev' => '2-47844552aae09c41a0ffffffffffffff')

    assert_equal true, r
  end

  def test_put_update_rev

    doc = { '_id' => 'soda0', 'type' => 'lemon' }

    r = @c.put(doc, :update_rev => true)

    assert_nil r
    assert_not_nil doc['_rev']
  end

  def test_put_update_rev_2nd_time

    @c.put({ '_id' => 'soda0b', 'type' => 'lemon' })
    doc = @c.get('soda0b')
    rev = doc['_rev']

    r = @c.put(doc, :update_rev => true)

    assert_nil r
    assert_not_equal rev, doc['_rev']
  end

  def test_re_put

    doc = @c.get('coffee1')
    @c.delete(doc)

    assert_nil @c.get('coffee1')

    doc['whatever'] = 'else'

    r = @c.put(doc)

    assert_not_nil @c.get('coffee1')['_rev']
  end

  def test_get

    doc = @c.get('coffee1')

    assert_not_nil doc['_rev']
  end

  def test_get_404

    doc = @c.get('tea0')

    assert_nil doc
  end

  def test_delete

    doc = @c.get('coffee1')

    r = @c.delete(doc)

    assert_nil r

    assert_nil(
      Rufus::Jig::Http.new('127.0.0.1', 5984).get('/rufus_jig_test/coffee1'))
  end

  def test_delete_2_args

    doc = @c.get('coffee1')

    @c.delete(doc['_id'], doc['_rev'])

    assert_nil(
      Rufus::Jig::Http.new('127.0.0.1', 5984).get('/rufus_jig_test/coffee1'))
  end

  def test_delete_conflict

    doc = @c.get('coffee1')

    rev = doc['_rev']

    doc['_rev'] = rev + '99'

    r = @c.delete(doc)

    assert_equal true, r
  end

  def test_get_doc_304

    doc = @c.get('coffee1')
    assert_equal 200, @c.http.last_response.status

    doc = @c.get('coffee1')
    assert_equal 304, @c.http.last_response.status
  end
end


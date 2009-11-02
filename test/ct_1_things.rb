
#
# testing rufus-jig
#
# Sun Nov  1 23:29:01 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')
require File.join(File.dirname(__FILE__), 'couch_base')


class CtThingsTest < Test::Unit::TestCase

  def setup

    @c = Rufus::Jig::CouchThing.new('127.0.0.1', 5984, '/rufus_jig_test')

    @c.delete rescue nil
    @c.put
  end

  def test_uuids

    uuids = @c.uuids

    assert_equal 1, uuids.length

    uuids = @c.uuids(5)

    assert_equal 5, uuids.length
  end

  def test_get

    assert_equal 'rufus_jig_test', @c.get['db_name']
  end

  def test_database

    assert_equal 'rufus_jig_test', @c.database.get['db_name']
  end

  def test_couch

    assert_equal 'Welcome', @c.couch.get['couchdb']
  end

  def test_put_new_empty_document

    doc = @c.put('doc0')

    assert_equal true, doc['ok']
    assert_not_nil doc['rev']

    assert_equal 'doc0', @c.get('doc0')['_id']
  end

  def test_put_new_document

    doc = @c.put('doc0', { 'a' => true })

    assert_equal true, doc['ok']
    assert_not_nil doc['rev']

    assert_equal true, @c.get('doc0')['a']
  end

  def test_conflict

    doc = @c.put('doc0', { 'a' => true })

    assert_equal 'conflict', @c.delete('doc0')['error']
    assert_equal 'conflict', @c.put('doc0', { 'a' => true })['error']
    assert_equal 'conflict', @c.put('doc0', { 'a' => false })['error']
  end

  def test_no_conflict

    @c.put('doc0', { 'a' => true })
    doc = @c.get('doc0')

    doc['a'] = false

    assert_equal true, @c.put('doc0', doc)['ok']
  end
end


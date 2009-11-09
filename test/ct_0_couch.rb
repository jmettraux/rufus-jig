
#
# testing rufus-jig
#
# Sun Nov  1 21:42:34 JST 2009
#

require File.join(File.dirname(__FILE__), 'couch_base')


class CtCouchTest < Test::Unit::TestCase

  def setup

    begin
      Rufus::Jig::Http.new('127.0.0.1', 5984).delete('/rufus_jig_test')
    rescue Exception => e
      #p e
    end

    @c = Rufus::Jig::Couch.get_couch('127.0.0.1', 5984)
  end

  def test_parent

    assert_nil @c.parent
  end

  def test_db

    assert_nil @c.db
  end

  def test_couch

    assert_equal @c, @c.couch
  end

  def test_welcome

    assert_equal 'Welcome', @c.get('.')['couchdb']
  end

  def test_uuids

    uuids = @c.get_uuids

    assert_equal 1, uuids.size

    uuids = @c.get_uuids(5)

    assert_equal 5, uuids.size
  end

  def test_get_databases

    dbs = @c.get_databases

    assert_equal Array, dbs.class
  end

  def test_put

    assert_equal({ 'ok' => true }, @c.put('rufus_jig_test', ''))

    assert_equal 'rufus_jig_test', @c.get('rufus_jig_test')['db_name']
  end

  def test_get_db

    assert_nil @c.get_db('rufus_jig_test')

    @c.put('rufus_jig_test', '')

    assert_equal 'rufus_jig_test', @c.get_db('rufus_jig_test').name
  end

  def test_put_db

    db = @c.put_db('rufus_jig_test')

    assert_equal 'rufus_jig_test', @c.get('rufus_jig_test')['db_name']
    assert_equal Rufus::Jig::CouchDatabase, @c.get_db('rufus_jig_test').class

    assert_raise(Rufus::Jig::CouchError) do
      db = @c.put_db('rufus_jig_test')
    end
  end

  def test_delete_db

    assert_raise(Rufus::Jig::CouchError) do
      @c.delete_db('rufus_jig_test')
    end

    @c.put_db('rufus_jig_test')

    @c.delete_db('rufus_jig_test')

    assert_nil @c.get_db('rufus_jig_test')
  end
end


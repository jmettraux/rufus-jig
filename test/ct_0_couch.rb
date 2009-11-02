
#
# testing rufus-jig
#
# Sun Nov  1 21:42:34 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')
require File.join(File.dirname(__FILE__), 'couch_base')


class CtCouchTest < Test::Unit::TestCase

  def setup

    begin
      Rufus::Jig::Http.new('127.0.0.1', 5984).delete('/rufus_jig_test')
    rescue Exception => e
      p e
    end
  end

  def test_welcome

    c = Rufus::Jig::CouchThing.new('127.0.0.1', 5984)

    assert_equal 'Welcome', c.get['couchdb']
  end

  def test_create_database

    c = Rufus::Jig::CouchThing.new('127.0.0.1', 5984)

    assert_equal({ 'ok' => true }, c.put('/rufus_jig_test', ''))

    assert_equal 'rufus_jig_test', c.get('/rufus_jig_test')['db_name']
    assert_equal 'rufus_jig_test', c.get('rufus_jig_test')['db_name']
  end

  def test_delete_database

    c = Rufus::Jig::CouchThing.new('127.0.0.1', 5984, 'rufus_jig_test')

    assert_nil c.get

    c.put

    assert_equal 'rufus_jig_test', c.get['db_name']

    c.delete

    assert_nil c.get
  end
end


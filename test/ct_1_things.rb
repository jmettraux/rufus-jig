
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

    @c.put rescue nil
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

  def test_get_document

    flunk
  end
end


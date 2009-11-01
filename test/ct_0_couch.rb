
#
# testing rufus-jig
#
# Sun Nov  1 21:42:34 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')
require File.join(File.dirname(__FILE__), 'couch_base')


class UtCouchTest < Test::Unit::TestCase

  def setup

    h = Rufus::Jig::Http.new('127.0.0.1', 5984)

    h.put('/rufus_jig_test') rescue nil

    @c = Rufus::Jig::CouchThing.new('127.0.0.1', 5984)
  end

  def test_welcome

    assert_equal 'Welcome', @c.get['couchdb']
  end
end


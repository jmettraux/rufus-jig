
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
      p e
    end

    @c = Rufus::Jig::Couch.new('127.0.0.1', 5984)
  end

  def test_welcome

    assert_equal 'Welcome', @c.get('.')['couchdb']
  end

  def test_put

    assert_equal({ 'ok' => true }, @c.put('rufus_jig_test', ''))

    assert_equal 'rufus_jig_test', @c.get('rufus_jig_test')['db_name']
  end

  def test_put_db

    assert_nil @c.get_db('rufus_jig_test')

    db = @c.put_db('rufus_jig_test')

    assert_equal 'rufus_jig_test', @c.get('rufus_jig_test')['db_name']
    assert_equal Rufus::Jig::CouchDatabase, @c.get_db('rufus_jig_test').class
  end

  def test_delete_db

    assert_raise(ArgumentError) do
      @c.delete_db('rufus_jig_test')
    end

    @c.put_db('rufus_jig_test')

    @c.delete_db('rufus_jig_test')

    assert_nil @c.get_db('rufus_jig_test')
  end
end



#
# testing rufus-jig
#
# Sat Nov  7 20:11:17 JST 2009
#

require File.join(File.dirname(__FILE__), 'couch_base')


class CtCouchClassMethodsTest < Test::Unit::TestCase

  def setup

    begin
      Rufus::Jig::Http.new('127.0.0.1', 5984).delete('/rufus_jig_test')
    rescue Exception => e
      #p e
    end
  end

  def test_get_couch

    c = Rufus::Jig::Couch.get_couch('127.0.0.1', 5984)

    assert_equal Rufus::Jig::Couch, c.class
    assert_equal '/', c.path
  end

  def test_get_db_missing

    assert_nil Rufus::Jig::Couch.get_db('127.0.0.1', 5984, 'rufus_jig_test')
    assert_nil Rufus::Jig::Couch.get_db('127.0.0.1', 5984, '/rufus_jig_test')
    #assert_nil Rufus::Jig::Couch.get_db('http://127.0.0.1:5984/rufus_jig_test')
  end

  def test_get_db

    Rufus::Jig::Http.new('127.0.0.1', 5984).put('/rufus_jig_test', '')

    assert_equal(
      'rufus_jig_test',
      Rufus::Jig::Couch.get_db('127.0.0.1', 5984, '/rufus_jig_test').name)

    assert_equal(
      'rufus_jig_test',
      Rufus::Jig::Couch.get_db('127.0.0.1', 5984, 'rufus_jig_test').name)
  end

  def test_put_db

    db = Rufus::Jig::Couch.put_db('127.0.0.1', 5984, 'rufus_jig_test')

    assert_equal 'rufus_jig_test', db.name

    assert_raise(Rufus::Jig::CouchError) {
      Rufus::Jig::Couch.put_db('127.0.0.1', 5984, 'rufus_jig_test')
    }
  end

  def test_put_db_slash

    db = Rufus::Jig::Couch.put_db('127.0.0.1', 5984, '/rufus_jig_test')

    assert_equal 'rufus_jig_test', db.name

    assert_raise(Rufus::Jig::CouchError) {
      Rufus::Jig::Couch.put_db('127.0.0.1', 5984, '/rufus_jig_test')
    }
  end

  def test_delete_db

    assert_raise(Rufus::Jig::CouchError) {
      Rufus::Jig::Couch.delete_db('127.0.0.1', 5984, 'rufus_jig_test')
    }

    Rufus::Jig::Couch.put_db('127.0.0.1', 5984, 'rufus_jig_test')

    assert_not_nil Rufus::Jig::Couch.get_db('127.0.0.1', 5984, 'rufus_jig_test')

    Rufus::Jig::Couch.delete_db('127.0.0.1', 5984, 'rufus_jig_test')

    assert_nil Rufus::Jig::Couch.get_db('http://127.0.0.1:5984/rufus_jig_test')
  end

  def test_get_doc

    Rufus::Jig::Http.new('127.0.0.1', 5984).put(
      '/rufus_jig_test', '')
    Rufus::Jig::Http.new('127.0.0.1', 5984).put(
      '/rufus_jig_test/doc0', { 'a' => 'b' }, :content_type => :json)

    doc = Rufus::Jig::Couch.get_doc('127.0.0.1', 5984, 'rufus_jig_test/doc0')

    assert_equal 'doc0', doc._id
    assert_not_nil doc._rev
  end

  def test_put_doc

    Rufus::Jig::Http.new('127.0.0.1', 5984).put('/rufus_jig_test', '')

    doc = Rufus::Jig::Couch.put_doc(
      'http://127.0.0.1:5984/rufus_jig_test/doc0', { 'x' => 'y' })

    assert_equal 'doc0', doc._id
    assert_not_nil doc._rev
  end

  def test_delete_doc

    Rufus::Jig::Http.new('127.0.0.1', 5984).put('/rufus_jig_test', '')

    assert_nil(
      Rufus::Jig::Couch.get_doc('127.0.0.1', 5984, 'rufus_jig_test/doc0'))

    assert_raise(Rufus::Jig::CouchError) {
      Rufus::Jig::Couch.delete_doc(
        'http://127.0.0.1:5984/rufus_jig_test/doc0')
    }

    Rufus::Jig::Http.new('127.0.0.1', 5984).put(
      '/rufus_jig_test/doc0', { 'a' => 'b' }, :content_type => :json)

    assert_raise(Rufus::Jig::CouchError) {
      Rufus::Jig::Couch.delete_doc(
        'http://127.0.0.1:5984/rufus_jig_test/doc0')
    }

    assert_not_nil(
      Rufus::Jig::Couch.get_doc('127.0.0.1', 5984, 'rufus_jig_test/doc0'))
  end
end


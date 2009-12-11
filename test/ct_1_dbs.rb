
#
# testing rufus-jig
#
# Sun Nov  1 23:29:01 JST 2009
#

require File.join(File.dirname(__FILE__), 'couch_base')


class CtDbsTest < Test::Unit::TestCase

  def setup

    begin
      Rufus::Jig::Http.new('127.0.0.1', 5984).delete('/rufus_jig_test')
    rescue Exception => e
      #p e
    end

    @c = Rufus::Jig::Couch.get_couch('127.0.0.1', 5984)
    @db = @c.put_db('rufus_jig_test')
  end

  def test_parent

    assert_equal @c, @db.parent
  end

  def test_db

    assert_equal @db, @db.db
  end

  def test_couch

    assert_equal @c, @db.couch
  end

  def test_put_doc

    doc = @db.put_doc('test0', { 'chocolate' => 'Villars' })

    assert_not_nil doc['_rev']
    assert_equal 'test0', doc['_id']
    assert_equal 'Villars', doc['chocolate']
  end

  def test_put_doc_1_arg

    doc = @db.put_doc('_id' => 'test0b', 'chocolate' => 'Camille Bloch')

    assert_not_nil doc['_rev']
    assert_equal 'test0b', doc['_id']
    assert_equal 'Camille Bloch', doc['chocolate']
  end

  def test_put_doc_fail

    @db.put_doc('_id' => 'test0c', 'chocolate' => 'Nestle Generics')

    assert_raise(Rufus::Jig::CouchError) {
      @db.put_doc('_id' => 'test0c', 'chocolate' => 'Nestle Generics')
    }
  end

  def test_get_doc

    @db.put_doc('test1', { 'chocolate' => 'Cailler' })

    doc = @db.get_doc('test1')

    assert_not_nil doc['_rev']
    assert_equal 'test1', doc['_id']
    assert_equal 'Cailler', doc['chocolate']
  end

  def test_delete_doc

    doc = @db.put_doc('test2', { 'chocolate' => 'Lindt' })

    @db.delete_doc('test2', doc._rev)

    assert_nil @db.get_doc('test2')
  end

  def test_delete_missing_doc

    assert_raise(ArgumentError) {
      p @db.delete_doc('test3', 'whatever')
    }
  end

  def test_conditional_get_doc

    @db.put_doc('test4', { 'chocolate' => 'Sprungli' })

    doc = @db.get_doc('test4')

    assert_equal 200, @db.http.last_response.status

    doc = doc.get

    assert_equal 304, @db.http.last_response.status
    assert_equal Rufus::Jig::CouchDocument, doc.class
  end
end



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
      p e
    end

    @c = Rufus::Jig::Couch.new('127.0.0.1', 5984)
    @db = @c.put_db('rufus_jig_test')
  end

  def test_put_doc

    doc = @db.put_doc('test0', { 'chocolate' => 'Villars' })

    assert_not_nil doc['_rev']
    assert_equal 'test0', doc['_id']
    assert_equal 'Villars', doc['chocolate']
  end

  def test_get_doc

    @db.put_doc('test1', { 'chocolate' => 'Cailler' })

    doc = @db.get_doc('test1')

    assert_not_nil doc['_rev']
    assert_equal 'test1', doc['_id']
    assert_equal 'Cailler', doc['chocolate']
  end

  def test_delete_doc

    @db.put_doc('test2', { 'chocolate' => 'Lindt' })

    @db.delete_doc('test2')

    assert_nil @db.get_doc('test1')
  end

  def test_delete_missing_doc

    assert_raise(ArgumentError) {
      @db.delete_doc('test3')
    }
  end

  def test_conditional_get_doc

    flunk
  end
end


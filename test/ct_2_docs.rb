
#
# testing rufus-jig
#
# Mon Nov  2 17:24:05 JST 2009
#

require File.join(File.dirname(__FILE__), 'couch_base')


class CtDocsTest < Test::Unit::TestCase

  def setup

    begin
      Rufus::Jig::Http.new('127.0.0.1', 5984).delete('/rufus_jig_test')
    rescue Exception => e
      p e
    end

    @c = Rufus::Jig::Couch.new('127.0.0.1', 5984)
    @db = @c.put_db('rufus_jig_test')

    @doc = @db.put_doc('ct2', { 'item' => 'suit', 'brand' => 'suit company' })
  end

  def test_doc_get

    @doc.get

    assert_equal 200, @doc.http.last_response.status

    @doc.get

    assert_equal 304, @doc.http.last_response.status
  end

  def test_doc_put

    rev = @doc._rev

    @doc['stained'] = true

    @doc.put

    p @doc._rev

    assert_not_equal rev, @doc._rev
    assert_equal 'suit', @doc['item']
  end

  def test_doc_delete

    @doc.delete

    assert_nil @db.get('ct2')

    assert_raise(Rufus::Jig::CouchError) {
      @doc.get
    }
  end
end


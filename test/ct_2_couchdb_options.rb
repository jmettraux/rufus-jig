
#
# testing rufus-jig
#
# Tue Dec 29 14:45:22 JST 2009
#

require File.join(File.dirname(__FILE__), 'couch_base')


class CtCouchDbOptionsTest < Test::Unit::TestCase

  def setup

    h = Rufus::Jig::Http.new('127.0.0.1', 5984)

    begin
      h.delete('/rufus_jig_test')
    rescue Exception => e
      #p e
    end

    h.put('/rufus_jig_test', '')
    h.put('/rufus_jig_test/coffee1', '{"_id":"coffee1","type":"ristretto"}')

    h.close

    @c = Rufus::Jig::Couch.new(
      '127.0.0.1', 5984, 'rufus_jig_test', :re_put_ok => false)
  end

  def teardown

    @c.close
  end

  def test_put_gone

    doc = @c.get('coffee1')
    @c.delete(doc)

    assert_nil @c.get('coffee1')

    doc['whatever'] = 'else'

    r = @c.put(doc)

    assert_equal true, r
  end
end


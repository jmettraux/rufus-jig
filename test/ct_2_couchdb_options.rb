
#
# testing rufus-jig
#
# Tue Dec 29 14:45:22 JST 2009
#

require File.join(File.dirname(__FILE__), 'couch_base')


class CtCouchDbOptionsTest < Test::Unit::TestCase

  def setup

    h = Rufus::Jig::Http.new(couch_url)

    begin
      h.delete('/rufus_jig_test')
    rescue Exception => e
      #p e
    end

    h.put('/rufus_jig_test', '')
    h.put('/rufus_jig_test/coffee2_0', '{"_id":"coffee2_0","type":"ristretto"}')

    h.close

    @c = Rufus::Jig::Couch.new(couch_url, 'rufus_jig_test')
  end

  def teardown

    @c.close
  end

  def test_put_gone

    doc = @c.get('coffee2_0')
    @c.delete(doc)

    assert_nil @c.get('coffee2_0')

    doc['whatever'] = 'else'

    r = @c.put(doc)

    assert_equal true, r
  end
end


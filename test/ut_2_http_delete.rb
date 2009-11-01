
#
# testing rufus-jig
#
# Sun Nov  1 11:59:20 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class UtHttpDeleteTest < Test::Unit::TestCase

  def setup

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567)
  end

  def test_delete

    r = @h.post('/documents', 'data', :content_type => 'text/plain')

    l = r.headers['Location']
    assert_equal 'data', @h.get(l)

    r = @h.delete(l)

    assert_equal 200, r.status

    assert_nil @h.get(l)
  end
end


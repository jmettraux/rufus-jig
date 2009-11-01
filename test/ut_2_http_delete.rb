
#
# testing rufus-jig
#
# Sun Nov  1 11:59:20 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class UtHttpDeleteTest < Test::Unit::TestCase

  def setup

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567)

    r = @h.put(
      '/documents/xyz', 'data', :content_type => 'text/plain', :raw => true)
  end

  def test_delete

    b = @h.delete('/documents/xyz')

    assert_equal 200, @h.last_response.status
    assert_equal({ 'deleted' => 'xyz' }, b)
  end

  def test_delete_raw

    r = @h.delete('/documents/xyz', :raw => true)

    assert_equal 200, r.status
    assert_equal "{\"deleted\":\"xyz\"}", r.body
  end
end



#
# testing rufus-jig
#
# Sun Nov  1 13:00:46 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class UtHttpPrefixTest < Test::Unit::TestCase

  def setup

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567, :prefix => '/a/b/')
  end

  def test_get

    b = @h.get('c')

    assert_equal 'C', b

    assert_equal({"/a/b/c"=>["\"123456123456\"", "C"]}, @h.cache)
  end

  def test_put

    b = @h.put('c', 'data')

    assert_equal 201, @h.last_response.status
  end

  def test_post

    b = @h.post('c', 'data')

    assert_equal 201, @h.last_response.status
  end

  def test_delete

    b = @h.delete('c')

    assert_equal 200, @h.last_response.status
  end
end


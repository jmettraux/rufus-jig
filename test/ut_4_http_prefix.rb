
#
# testing rufus-jig
#
# Sun Nov  1 13:00:46 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class UtHttpPrefixTest < Test::Unit::TestCase

  def setup

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567, :prefix => '/a/b/')

    class << @h
      attr_reader :cache
    end
  end

  def test_get

    r = @h.get('c')

    assert_equal 'C', r

    assert_equal({ '/a/b/c' => 'C' }, @h.cache)
  end

  def test_put

    r = @h.put('c', 'data')

    assert_equal 201, r.status
  end

  def test_post

    r = @h.post('c', 'data')

    assert_equal 201, r.status
  end

  def test_delete

    r = @h.delete('c')

    assert_equal 200, r.status
  end
end


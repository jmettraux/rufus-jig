
#
# testing rufus-jig
#
# Sun Nov  1 13:00:46 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class UtHttpMiscTest < Test::Unit::TestCase

  def test_prefix

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567, :prefix => '/a/b')

    assert_equal 'c', @h.get('/c')
    assert_equal 'C', @h.get('c')

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567, :prefix => 'a/b')

    assert_equal 'c', @h.get('/c')
    assert_equal 'C', @h.get('c')

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567)

    assert_equal 'C', @h.get('/a/b/c')
    assert_equal 'C', @h.get('a/b/c')

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567, :prefix => '/')

    assert_equal 'C', @h.get('/a/b/c')
    assert_equal 'C', @h.get('a/b/c')

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567, :prefix => '')

    assert_equal 'C', @h.get('/a/b/c')
    assert_equal 'C', @h.get('a/b/c')
  end

  def test_no_prefix

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567, :prefix => '/a/b')

    assert_equal({ 'car' => 'Mercedes-Benz' }, @h.get('/document'))
    assert_equal(nil, @h.get('document'))
  end
end


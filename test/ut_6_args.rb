
#
# testing rufus-jig
#
# Sun Nov  8 11:57:39 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class UtArgsTest < Test::Unit::TestCase

  def test_extract_args

    # [ http, path, payload, opts ]

    a = eh(false, 'http://127.0.0.1:5984')
    assert_equal '127.0.0.1', a[0].host
    assert_equal 5984, a[0].port
    assert_equal '/', a[1]
    assert_equal nil, a[2]
    assert_equal '{}', a[3].inspect

    a = eh(false, '127.0.0.1', 5984, '/')
    assert_equal '127.0.0.1', a[0].host
    assert_equal 5984, a[0].port
    assert_equal '/', a[1]
    assert_equal nil, a[2]
    assert_equal '{}', a[3].inspect

    a = eh(false, '127.0.0.1', 5984, '/', :option => true)
    assert_equal '127.0.0.1', a[0].host
    assert_equal 5984, a[0].port
    assert_equal '/', a[1]
    assert_equal nil, a[2]
    assert_equal '{:option=>true}', a[3].inspect
  end

  def test_payload_expected

    a = eh(true, 'http://127.0.0.1:5984', [ 1, 2, 3 ])
    assert_equal '127.0.0.1', a[0].host
    assert_equal 5984, a[0].port
    assert_equal '/', a[1]
    assert_equal [ 1, 2, 3 ], a[2]
    assert_equal '{}', a[3].inspect

    assert_raise(ArgumentError) {
      eh(true, 'http://127.0.0.1:5984', :nada, [ 1, 2, 3 ])
    }
  end

  def test_payload_is_a_hash

    a = eh(true, 'http://127.0.0.1:5984', { 'cheese' => 'burger' })
    assert_equal '127.0.0.1', a[0].host
    assert_equal 5984, a[0].port
    assert_equal '/', a[1]
    assert_equal '{"cheese"=>"burger"}', a[2].inspect
    assert_equal '{}', a[3].inspect

    a = eh(true, 'http://127.0.0.1:5984', { 'cheese' => 'burger' }, { :cache => true })
    assert_equal '127.0.0.1', a[0].host
    assert_equal 5984, a[0].port
    assert_equal '/', a[1]
    assert_equal '{"cheese"=>"burger"}', a[2].inspect
    assert_equal '{:cache=>true}', a[3].inspect
  end

  protected

  def eh (pe, *args)

    Rufus::Jig::Http.extract_http(pe, *args)
  end
end


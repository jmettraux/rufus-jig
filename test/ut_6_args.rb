
#
# testing rufus-jig
#
# Sun Nov  8 11:57:39 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class UtArgsTest < Test::Unit::TestCase

  def test_simple_uri

    h = Rufus::Jig::Http.new('http://127.0.0.1:5984')

    assert_equal 'http', h.scheme
    assert_equal '127.0.0.1', h.host
    assert_equal 5984, h.port
    assert_equal '', h._path
    assert_equal nil, h._query
    assert_equal nil, h.options[:basic_auth]
  end

  def test_uri_with_path_and_query

    h = Rufus::Jig::Http.new('http://127.0.0.1:5984/nada?a=b&c=d')

    assert_equal 'http', h.scheme
    assert_equal '127.0.0.1', h.host
    assert_equal 5984, h.port
    assert_equal '/nada', h._path
    assert_equal 'a=b&c=d', h._query
    assert_equal nil, h.options[:basic_auth]
  end

  def test_uri_with_basic_auth

    h = Rufus::Jig::Http.new('http://u:p@127.0.0.1:5984')

    assert_equal 'http', h.scheme
    assert_equal '127.0.0.1', h.host
    assert_equal 5984, h.port
    assert_equal '', h._path
    assert_equal nil, h._query
    assert_equal %w[ u p ], h.options[:basic_auth]
  end

  def test_host_port

    h = Rufus::Jig::Http.new('127.0.0.1', 5984)

    assert_equal 'http', h.scheme
    assert_equal '127.0.0.1', h.host
    assert_equal 5984, h.port
    assert_equal nil, h._path
    assert_equal nil, h._query
    assert_equal nil, h.options[:basic_auth]
  end

  def test_host_port_path

    h = Rufus::Jig::Http.new('127.0.0.1', 5984, '/banana')

    assert_equal 'http', h.scheme
    assert_equal '127.0.0.1', h.host
    assert_equal 5984, h.port
    assert_equal '/banana', h._path
    assert_equal nil, h._query
    assert_equal nil, h.options[:basic_auth]
  end

  def test_host_port_path_options

    h = Rufus::Jig::Http.new(
      '127.0.0.1', 5984, '/banana', :basic_auth => %w[ u p ])

    assert_equal 'http', h.scheme
    assert_equal '127.0.0.1', h.host
    assert_equal 5984, h.port
    assert_equal '/banana', h._path
    assert_equal nil, h._query
    assert_equal %w[ u p ], h.options[:basic_auth]
  end

  def test_uri_plus_path

    h = Rufus::Jig::Http.new('http://127.0.0.1:5984', '/banana')

    assert_equal 'http', h.scheme
    assert_equal '127.0.0.1', h.host
    assert_equal 5984, h.port
    assert_equal '/banana', h._path
    assert_equal nil, h._query
    assert_equal nil, h.options[:basic_auth]
  end
end



#
# testing rufus-jig
#
# Fri Oct 30 17:57:15 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class UtHttpGetTest < Test::Unit::TestCase

  def setup

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567)

    class << @h
      attr_reader :cache
    end
  end

  def test_get

    r = @h.get('/document')

    assert_equal Hash, r.class
    assert_equal 'Mercedes-Benz', r['car']

    assert_equal 0, @h.cache.size
  end

  def test_get_with_accept

    r = @h.get('/document_accept', :accept => 'text/plain')

    assert_equal '{"car":"Saab"}', r

    r = @h.get('/document_accept', :accept => 'application/json')

    assert_equal Hash, r.class
    assert_equal 'Saab', r['car']

    assert_equal 0, @h.cache.size
  end

  def test_conditional_get

    r = @h.get('/document_with_etag')

    etag = @h.last_response.headers['Etag']

    assert_equal Hash, r.class
    assert_equal 'Peugeot', r['car']

    assert_equal 200, @h.last_response.status

    assert_equal({"/document_with_etag"=>{"car"=>"Peugeot"}}, @h.cache)

    r = @h.get('/document_with_etag', :etag => etag)

    assert_equal Hash, r.class
    assert_equal 'Peugeot', r['car']

    assert_equal 304, @h.last_response.status

    assert_equal 1, @h.cache.size
  end
end


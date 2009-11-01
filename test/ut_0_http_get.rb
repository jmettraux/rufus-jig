
#
# testing rufus-jig
#
# Fri Oct 30 17:57:15 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class UtHttpGetTest < Test::Unit::TestCase

  def setup

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567)
  end

  def test_get

    r = @h.get('/document')

    assert_equal Hash, r.class
    assert_equal 'Mercedes-Benz', r['car']

    assert_equal 0, @h.cache.size
  end

  def test_get_raw

    r = @h.get('/document', :raw => true)

    assert_equal 200, r.status
    assert_equal "{\"car\":\"Mercedes-Benz\"}", r.body
  end

  def test_get_404

    r = @h.get('/missing')

    assert_nil r
  end

  def test_get_404_raw

    r = @h.get('/missing', :raw => true)

    assert_equal 404, r.status
  end

  def test_get_500

    assert_raise Rufus::Jig::HttpError do
      @h.get('/server_error')
    end

    assert 500, @h.last_response.status
  end

  def test_get_500_raw

    r = @h.get('/server_error', :raw => true)

    assert 500, r.status
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

    assert_equal({"/document_with_etag"=>["\"123456123456\"", {"car"=>"Peugeot"}]}, @h.cache)

    r = @h.get('/document_with_etag', :etag => etag)

    assert_equal Hash, r.class
    assert_equal 'Peugeot', r['car']

    assert_equal 304, @h.last_response.status

    assert_equal 1, @h.cache.size
  end
end


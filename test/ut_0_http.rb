
#
# testing rufus-jig
#
# Fri Oct 30 17:57:15 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class UtHttpTest < Test::Unit::TestCase

  def setup
    @h = Rufus::Jig::Http.new('127.0.0.1', 4567)
  end

  def test_get

    r = @h.get('/document')

    assert_equal Hash, r.class
    assert_equal 'Mercedes-Benz', r['car']
  end

  def test_get_with_accept

    r = @h.get('/document_accept', :accept => 'text/plain')

    assert_equal '{"car":"Saab"}', r

    r = @h.get('/document_accept', :accept => 'application/json')

    assert_equal Hash, r.class
    assert_equal 'Saab', r['car']
  end

  def test_conditional_get

    r = @h.get('/document_with_etag')

    etag = @h.last_response.headers['Etag']

    assert_equal Hash, r.class
    assert_equal 'Peugeot', r['car']

    assert_equal 200, @h.last_response.status

    r = @h.get('/document_with_etag', :etag => etag)

    assert_equal Hash, r.class
    assert_equal 'Peugeot', r['car']

    assert_equal 304, @h.last_response.status
  end
end


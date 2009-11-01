
#
# testing rufus-jig
#
# Sat Oct 31 23:27:02 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class UtHttpPostTest < Test::Unit::TestCase

  def setup

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567)

    @h.delete('/documents')
  end

  def test_post

    b = @h.post('/documents', '{"msg":"hello"}', :content_type => 'application/json')

    r = @h.last_response

    l = r.headers['Location']

    assert_equal 'created.', b
    assert_equal 201, r.status
    assert_not_nil l

    assert_equal({ 'msg' => 'hello' }, @h.get(l))
  end

  def test_post_and_decode_body

    b = @h.post(
      '/documents?mirror=true', '{"msg":"hello world"}', :content_type => :json)

    assert_equal({ 'msg' => 'hello world' }, b)

    assert_equal 0, @h.cache.size
  end

  def test_post_and_cache

    b = @h.post(
      '/documents?etag=true', '{"msg":"hello world"}', :content_type => :json)

    assert_equal({ 'msg' => 'hello world' }, b)

    assert_equal 1, @h.cache.size
  end
end


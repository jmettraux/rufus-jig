
#
# testing rufus-jig
#
# Sat Oct 31 23:27:02 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class UtHttpPutTest < Test::Unit::TestCase

  def setup
    @h = Rufus::Jig::Http.new('127.0.0.1', 4567)
    @h.delete('/documents')
  end
  def teardown
    @h.close
  end

  def test_clean

    assert_nil @h.get('/documents/1234')
  end

  def test_put

    b = @h.put('/documents/1234', '{"msg":"hello"}', :content_type => 'application/json')

    assert_equal 201, @h.last_response.status

    assert_equal({ 'msg' => 'hello' }, @h.get('/documents/1234'))
  end

  def test_put_json

    r = @h.put(
      '/documents/5678',
      { 'msg' => 'hello' },
      :content_type => 'application/json')

    assert_equal 201, @h.last_response.status

    assert_equal({ 'msg' => 'hello' }, @h.get('/documents/5678'))
  end

  def test_put_colon_json

    b = @h.put(
      '/documents/abcd',
      { 'msg' => 'hello' },
      :content_type => :json)

    assert_equal 201, @h.last_response.status

    assert_equal({ 'msg' => 'hello' }, @h.get('/documents/abcd'))
  end

  def test_put_and_decode_body

    b = @h.put(
      '/documents/yyyy?mirror=true',
      '{"msg":"hello world"}',
      :content_type => :json)

    assert_equal({ 'msg' => 'hello world' }, b)
    assert_equal 0, @h.cache.size
  end

  def test_put_and_cache

    b = @h.put(
      '/documents/yyyy?etag=true',
      '{"msg":"hello world"}',
      :content_type => :json)

    assert_equal({ 'msg' => 'hello world' }, b)
    assert_equal 1, @h.cache.size
  end

  def test_put_conflict

    r = @h.put('/conflict', '')

    assert_equal true, r
  end

  def test_put_long_stuff

    data = 'x' * 5000

    b = @h.put('/documents/abcd', data, :content_type => 'image/png')

    assert_equal 201, @h.last_response.status
  end

  def test_put_image

    data = File.read(File.join(File.dirname(__FILE__), 'tweet.png'))

    b = @h.put('/documents/img0', data, :content_type => 'image/png')

    assert_equal 201, @h.last_response.status
  end
end


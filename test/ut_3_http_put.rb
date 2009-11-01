
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

  def test_clean

    assert_nil @h.get('/documents/1234')
  end

  def test_put

    r = @h.put('/documents/1234', '{"msg":"hello"}', :content_type => 'application/json')

    assert_equal 201, r.status

    assert_equal({ 'msg' => 'hello' }, @h.get('/documents/1234'))
  end

  def test_put_json

    r = @h.put(
      '/documents/5678',
      { 'msg' => 'hello' },
      :content_type => 'application/json')

    assert_equal 201, r.status

    assert_equal({ 'msg' => 'hello' }, @h.get('/documents/5678'))
  end

  def test_put_colon_json

    r = @h.put(
      '/documents/abcd',
      { 'msg' => 'hello' },
      :content_type => :json)

    assert_equal 201, r.status

    assert_equal({ 'msg' => 'hello' }, @h.get('/documents/abcd'))
  end
end


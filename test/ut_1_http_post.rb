
#
# testing rufus-jig
#
# Sat Oct 31 23:27:02 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class UtHttpPostTest < Test::Unit::TestCase

  def setup

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567)
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
end


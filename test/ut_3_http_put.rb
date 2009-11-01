
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

  def test_put

    assert_nil @h.get('/documents/1234')

    r = @h.put('/documents/1234', '{"msg":"hello"}', :content_type => 'application/json')

    assert_equal 201, r.status

    assert_equal({ 'msg' => 'hello' }, @h.get('/documents/1234'))
  end
end


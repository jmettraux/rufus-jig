
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

    r = @h.post('/stuff', 'data')

    assert_equal 201, r.status
  end
end


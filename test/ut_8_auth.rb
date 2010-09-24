
#
# testing rufus-jig
#
# Fri Sep 24 17:11:26 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')


class UtAuthTest < Test::Unit::TestCase

  def setup
    @h = Rufus::Jig::Http.new(
      '127.0.0.1', 4567, :basic_auth => %w[ admin nimda ])
  end
  def teardown
    @h.close
  end

  def test_denied

    h = Rufus::Jig::Http.new('127.0.0.1', 4567)

    assert_raise Rufus::Jig::HttpError do
      h.get('/protected')
    end
  end

  def test_authorized

    assert_equal(
      { 'info' => 'secretive' },
      @h.get('/protected'))
  end
end


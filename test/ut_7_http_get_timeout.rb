
#
# testing rufus-jig
#
# Tue Mar  9 11:09:43 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')


class UtHttpGetTimeoutTest < Test::Unit::TestCase

  #def setup
  #end
  def teardown
    @h.close
  end

  def test_timeout_after_1

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567, :timeout => 1)

    assert_raise Rufus::Jig::TimeoutError do
      @h.get('/later')
    end
  end

  def test_timeout_after_5

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567)

    assert_raise Rufus::Jig::TimeoutError do
      @h.get('/later')
    end
  end

  def test_timeout_after_15

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567, :timeout => 15)

    r = @h.get('/later')

    assert_equal 'later', r
  end

  def test_never_timeout

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567, :timeout => -1)

    r = @h.get('/later')

    assert_equal 'later', r
  end
end



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

    t = nil

    assert_raise Rufus::Jig::TimeoutError do
      t = Time.now
      @h.get('/later')
    end

    d = Time.now - t; dd = 4.0; assert d < dd, "after #{d} seconds (#{dd})"
      # grr, em-http-request forces me to use 4.0 (2.0 for the others)
  end

  def test_timeout_after_5

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567)

    t = nil

    assert_raise Rufus::Jig::TimeoutError do
      t = Time.now
      @h.get('/later')
    end

    d = Time.now - t; dd = 7.0; assert d < dd, "after #{d} seconds (#{dd})"
  end

  def test_timeout_after_15

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567, :timeout => 15)

    t = Time.now

    r = begin
      @h.get('/later')
    rescue Rufus::Jig::TimeoutError => e
      puts " :( timed out after #{Time.now - t} seconds"
      flunk
    end

    assert_equal 'later', r
    d = Time.now - t; dd = 8.0; assert d < dd, "after #{d} seconds (#{dd})"
  end

  def test_never_timeout

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567, :timeout => -1)

    t = Time.now

    r = @h.get('/later')

    assert_equal 'later', r
    d = Time.now - t; dd = 8.0; assert d < dd, "after #{d} seconds (#{dd})"
  end

  def test_request_timeout_after_1

    @h = Rufus::Jig::Http.new('127.0.0.1', 4567, :timeout => 15)

    t = nil

    assert_raise Rufus::Jig::TimeoutError do
      t = Time.now
      @h.get('/later', :timeout => 1)
    end

    d = Time.now - t; dd = 4.0; assert d < dd, "after #{d} seconds (#{dd})"
      # grr, em-http-request forces me to use 4.0 (2.0 for the others)
  end
end


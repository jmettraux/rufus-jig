
#
# testing rufus-jig
#
# Sun Sep 26 18:26:15 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')


class UtAuthTest < Test::Unit::TestCase

  def setup
    @c = Rufus::Jig::Couch.new(
      '127.0.0.1', 4567, 'tcouch', :basic_auth => %w[ admin nimda ])
  end
  def teardown
    @c.close
  end

  def test_denied

    c = Rufus::Jig::Couch.new('127.0.0.1', 4567, 'tcouch')

    assert_raise Rufus::Jig::HttpError do
      c.get('.')
    end
  end

  def test_authorized

    assert_equal({ 'id' => 'nada' }, @c.get('.'))
  end

  def test_on_change

    res = nil

    t = Thread.new {
      @c.on_change do |id, deleted, doc|
        res = [ id, deleted, doc ]
      end
    }

    sleep 0.200

    t.kill

    assert_equal [ 'x', false, { 'hello' => 'world' } ], res
  end

  def test_on_change_denied

    c = Rufus::Jig::Couch.new('127.0.0.1', 4567, 'tcouch')

    assert_raise Rufus::Jig::HttpError do
      c.on_change do |id, deleted, doc|
      end
    end
  end
end


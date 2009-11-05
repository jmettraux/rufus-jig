
#
# testing rufus-jig
#
# Mon Nov  2 17:24:05 JST 2009
#

require File.join(File.dirname(__FILE__), 'couch_base')


class CtDocsTest < Test::Unit::TestCase

  def setup

    begin
      Rufus::Jig::Http.new('127.0.0.1', 5984).delete('/rufus_jig_test')
    rescue Exception => e
      p e
    end

    @c = Rufus::Jig::Couch.new('127.0.0.1', 5984)
    @db = @c.put_db('rufus_jig_test')
  end

  def test_whatever

    flunk
  end
end


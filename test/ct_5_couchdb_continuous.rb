# encoding: UTF-8

#
# testing rufus-jig
#
# Tue May 11 09:52:37 JST 2010
#

require File.join(File.dirname(__FILE__), 'couch_base')


class CtCouchDbContinuousTest < Test::Unit::TestCase

  def setup

    h = Rufus::Jig::Http.new(couch_url)

    begin
      h.delete('/rufus_jig_test')
    rescue Exception => e
      #p e
    end
    h.put('/rufus_jig_test', '')
    h.close

    @c = Rufus::Jig::Couch.new(couch_url, 'rufus_jig_test')
  end

  def teardown

    @c.close
  end

  def test_on_change

    stack = []

    t = Thread.new do
      @c.on_change { |doc_id, deleted| stack << doc_id }
    end

    @c.put('_id' => 'angel0', 'name' => 'samael')
    @c.put('_id' => 'angel1', 'name' => 'raphael')

    sleep 0.150
    t.kill

    assert_equal 2, stack.size
  end

  def test_on_change_include_docs

    stack = []

    Thread.abort_on_exception = true

    t = Thread.new do
      @c.on_change { |doc_id, deleted, doc| stack << doc }
    end

    @c.put('_id' => 'angel2', 'name' => 'samael')
    @c.put('_id' => 'angel3', 'name' => 'ゆきひろ')

    sleep 0.150
    t.kill

    assert_equal 'ゆきひろ', stack[1]['name']
  end

  def test_on_change_include_docs_with_deleted

    stack = []

    Thread.abort_on_exception = true

    t = Thread.new do
      @c.on_change { |doc_id, deleted, doc| stack << [ doc_id, deleted ] }
    end

    @c.put('_id' => 'angel4', 'name' => 'samael')
    sleep 0.077
    @c.delete(@c.get('angel4'))

    sleep 0.154
    t.kill

    assert_equal [["angel4", false], ["angel4", true]], stack
  end
end


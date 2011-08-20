# encoding: UTF-8

#
# specifying rufus-jig
#
# Tue Nov 30 10:16:03 JST 2010
#

require File.expand_path('../../spec_helper.rb', __FILE__)


describe Rufus::Jig::Couch do

  context 'and feed=continuous' do

    before(:each) do

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

    after(:each) do

      @c.close
    end

    describe '#on_change' do

      it 'intercepts changes' do

        stack = []

        t = Thread.new do
          @c.on_change { |doc_id, deleted| stack << doc_id }
        end

        @c.put('_id' => 'angel0', 'name' => 'samael')
        @c.put('_id' => 'angel1', 'name' => 'raphael')

        sleep 0.500
        t.kill

        stack.size.should == 2
      end

      it 'intercepts changes and docs' do

        stack = []

        Thread.abort_on_exception = true

        t = Thread.new do
          @c.on_change { |doc_id, deleted, doc| stack << doc }
        end

        @c.put('_id' => 'angel2', 'name' => 'samael')
        @c.put('_id' => 'angel3', 'name' => 'ゆきひろ')

        sleep 0.500
        t.kill

        stack[1]['name'].should == 'ゆきひろ'
      end

      it 'intercepts changes and among them, doc deletions' do

        stack = []

        Thread.abort_on_exception = true

        t = Thread.new do
          @c.on_change { |doc_id, deleted, doc| stack << [ doc_id, deleted ] }
        end

        @c.put('_id' => 'angel4', 'name' => 'samael')
        sleep 0.077
        @c.delete(@c.get('angel4'))

        sleep 0.500
        t.kill

        ([["angel4", false], ["angel4", true]] == stack ||
         [["angel4", true]] == stack).should == true
      end
    end
  end
end


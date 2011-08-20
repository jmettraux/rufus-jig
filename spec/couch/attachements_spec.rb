
#
# specifying rufus-jig
#
# Tue Nov 30 09:12:59 JST 2010
#

require File.expand_path('../../spec_helper.rb', __FILE__)


describe Rufus::Jig::Couch do

  context 'with attachments' do

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

      @c.put('_id' => 'thedoc', 'function' => 'recipient for attachements')
      @d = @c.get('thedoc')
    end

    after(:each) do

      @c.close
    end

    describe '#attach' do

      it 'attaches' do

        @c.attach(
          'thedoc', @d['_rev'], 'message', 'this is a message',
          :content_type => 'text/plain')

        @c.get('thedoc/message').should == 'this is a message'
      end

      it 'attaches with the right content-type' do

        @c.attach(
          'thedoc', @d['_rev'], 'message', 'this is a message',
          :content_type => 'text/plain')

        r = @c.get('thedoc/message', :raw => true)
        r.status.should == 200
        r.headers['Content-Type'].should == 'text/plain'
      end

      it 'returns the couch response' do

        r = @c.attach(
          'thedoc', @d['_rev'], 'message', 'this is a message',
          :content_type => 'text/plain')

        r.keys.sort.should == %w[ id ok rev ]
      end

      it 'raises if it failed' do

        lambda {
          @c.attach(
            'thedoc', '999-123e', 'message', 'this is a message',
            :content_type => 'text/plain')
        }.should raise_error
      end
    end

    describe '#detach' do

      before(:each) do

        r = @c.attach(
          'thedoc', @d['_rev'],
          'image', File.read(File.join(File.dirname(__FILE__), 'tweet.png')),
          :content_type => 'image/png')
        @d['_rev'] = r['rev']
      end

      it 'detaches' do

        @c.detach('thedoc', @d['_rev'], 'image')

        @c.get('thedoc/image').should == nil
      end

      it 'returns the couch response' do

        r = @c.detach('thedoc', @d['_rev'], 'image')

        r.keys.sort.should == %w[ id ok rev ]
      end

      it 'raises if it failed' do

        lambda {
          @c.detach('thedoc', '999-12340e', 'image')
        }.should raise_error
      end
    end

    describe '#get' do

      before(:each) do

        r = @c.attach(
          'thedoc', @d['_rev'],
          'image', File.read(File.join(File.dirname(__FILE__), 'tweet.png')),
          :content_type => 'image/png')
        @d['_rev'] = r['rev']
      end

      context 'without :attachments => true' do

        it 'returns the attachment as a stub' do

          doc = @c.get('thedoc')

          doc['_attachments']['image']['stub'].should == true
          doc['_attachments']['image']['data'].should == nil
        end
      end

      context 'with :attachments => true' do

        it 'returns the attachment encoded in base64' do

          doc = @c.get('thedoc', :attachments => true)

          doc['_attachments']['image']['stub'].should == nil
          doc['_attachments']['image']['data'].should_not == nil
        end
      end
    end
  end
end


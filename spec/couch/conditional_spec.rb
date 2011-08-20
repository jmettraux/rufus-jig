
#
# specifying rufus-jig
#
# Mon Dec  6 20:16:11 JST 2010
#

require File.expand_path('../../spec_helper.rb', __FILE__)


describe Rufus::Jig::Couch do

  context 'with conditional GET (and POST)' do

    before(:each) do

      h = Rufus::Jig::Http.new(couch_url)

      begin
        h.delete('/rufus_jig_test')
      rescue Exception => e
        #p e
      end

      h.put('/rufus_jig_test', '')

      h.put('/rufus_jig_test/d0', '{"_id":"d0","type":"door"}')
      h.put('/rufus_jig_test/d1', '{"_id":"d1","type":"window"}')
      h.put('/rufus_jig_test/d2', '{"_id":"d2","type":"window"}')
      h.put('/rufus_jig_test/d3', '{"_id":"d3","type":"wall"}')
      h.put('/rufus_jig_test/d4', '{"_id":"d4","type":"roof"}')

      h.put(
        '/rufus_jig_test/_design/my_test',
        {
          '_id' => '_design/my_test',
          'views' => {
            'my_view' => {
              'map' => "function(doc) { emit(doc['type'], null); }"
            }
          }
        },
        :content_type => :json)

      h.close

      @c = Rufus::Jig::Couch.new(couch_url, 'rufus_jig_test')
    end

    after(:each) do

      @c.close
    end

    describe '#get' do

      it 'caches _all_docs' do

        @c.get('_all_docs')
        s0 = @c.http.last_response.status
        @c.get('_all_docs')
        s1 = @c.http.last_response.status

        s0.should == 200
        s1.should == 304
      end
    end

    describe '#post with :keys' do

      it "doesn't cache by default" do

        @c.post('_all_docs', { 'keys' => %w[ d0 d2 ] })
        s0 = @c.http.last_response.status
        @c.post('_all_docs', { 'keys' => %w[ d0 d2 ] })
        s1 = @c.http.last_response.status

        s0.should == 200
        s1.should == 200
      end

      it 'caches _all_docs when :cache => true' do

        @c.post('_all_docs', { 'keys' => %w[ d1 d2 ] }, :cache => true)
        s0 = @c.http.last_response.status
        @c.post('_all_docs', { 'keys' => %w[ d1 d2 ] }, :cache => true)
        s1 = @c.http.last_response.status

        s0.should == 200
        s1.should == 304
      end

      it 'caches _all_docs too much when :cache => true' do

        @c.post('_all_docs', { 'keys' => %w[ d1 d2 ] }, :cache => true)
        s0 = @c.http.last_response.status
        @c.post('_all_docs', { 'keys' => %w[ d0 d2 ] }, :cache => true)
        s1 = @c.http.last_response.status

        s0.should == 200
        s1.should == 304
      end

      it 'caches _all_docs when :cache => :with_body' do

        @c.post('_all_docs', { 'keys' => %w[ d2 d3 ] }, :cache => :with_body)
        s0 = @c.http.last_response.status
        @c.post('_all_docs', { 'keys' => %w[ d2 d3 ] }, :cache => :with_body)
        s1 = @c.http.last_response.status

        s0.should == 200
        s1.should == 304
      end

      it "doesn't cache _all_docs too much when :cache => :with_body" do

        @c.post('_all_docs', { 'keys' => %w[ d2 d3 ] }, :cache => :with_body)
        s0 = @c.http.last_response.status
        @c.post('_all_docs', { 'keys' => %w[ d0 d3 ] }, :cache => :with_body)
        s1 = @c.http.last_response.status

        s0.should == 200
        s1.should == 200
      end
    end

    describe '#query' do

      it 'caches as expected with :keys' do

        @c.query('my_test:my_view', :keys => %w[ door window ])
        s0 = @c.http.last_response.status
        @c.query('my_test:my_view', :keys => %w[ door window ])
        s1 = @c.http.last_response.status

        s0.should == 200
        s1.should == 304
      end

      it 'does not cache when the :keys are different' do

        @c.query('my_test:my_view', :keys => %w[ door window ])
        s0 = @c.http.last_response.status
        @c.query('my_test:my_view', :keys => %w[ door wall ])
        s1 = @c.http.last_response.status

        s0.should == 200
        s1.should == 200
      end
    end

    describe '#all' do

      it 'caches as expected with :keys' do

        @c.all(:keys => %w[ d0 d3 ])
        s0 = @c.http.last_response.status
        @c.all(:keys => %w[ d0 d3 ])
        s1 = @c.http.last_response.status

        s0.should == 200
        s1.should == 304
      end

      it 'does not cache when the :keys are different' do

        @c.all(:keys => %w[ d0 d3 ])
        s0 = @c.http.last_response.status
        @c.all(:keys => %w[ d1 d3 ])
        s1 = @c.http.last_response.status

        s0.should == 200
        s1.should == 200
      end
    end
  end
end


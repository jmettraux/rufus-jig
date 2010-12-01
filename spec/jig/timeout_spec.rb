
#
# specifiying rufus-jig
#
# Wed Dec  1 16:13:45 JST 2010
#

require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')


describe Rufus::Jig::Http do

  after(:each) do
    @h.close
  end

  context 'with a timeout of 1 second' do

    before(:each) do
      @h = Rufus::Jig::Http.new('127.0.0.1', 4567, :timeout => 1)
    end

    it 'times out' do

      lambda { @h.get('/later') }.should raise_error(Rufus::Jig::TimeoutError)
    end

    it 'times out after 1 second' do

      t = Time.now

      @h.get('/later') rescue nil

      (Time.now - t).should be < (@h.variant == :em ? 3.0 : 2.0)
    end
  end

  context 'with a timeout of -1' do

    before(:each) do
      @h = Rufus::Jig::Http.new('127.0.0.1', 4567, :timeout => -1)
    end

    it 'never times out' do

      @h.get('/later').should == 'later'
    end
  end

  context 'with a request defined timeout' do

    before(:each) do
      @h = Rufus::Jig::Http.new('127.0.0.1', 4567, :timeout => 15)
    end

    it 'times out' do

      lambda {
        @h.get('/later', :timeout => 1)
      }.should raise_error(Rufus::Jig::TimeoutError)
    end

    it 'times out after 1 second' do

      t = Time.now

      @h.get('/later', :timeout => 1) rescue nil

      (Time.now - t).should be < (@h.variant == :em ? 3.0 : 2.0)
    end
  end
end


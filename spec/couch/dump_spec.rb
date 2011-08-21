
#
# specifying rufus-jig
#
# Sun Aug 21 08:04:11 JST 2011
#

require File.expand_path('../../spec_helper.rb', __FILE__)


describe Rufus::Jig::Couch do

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

  describe '#dump' do

    before(:each) do

      @c.put('_id' => 'doc0', 'msg' => 'hello world')
      @c.put('_id' => 'doc1', 'msg' => 'hello world again')

      @c.put('_id' => 'doc2', '_attachments' => { 'msg' => {
        'data' => 'aGVsbG8gd29ybGQ=',
        'content_type' => 'text/plain'
      } })

      FileUtils.rm('out.dump') rescue nil
    end

    it 'dumps to a file' do

      @c.dump('out.dump')

      File.exist?('out.dump').should == true
    end

    it 'dumps one line per document' do

      @c.dump('out.dump')

      File.readlines('out.dump').each do |line|
        Rufus::Json.decode(line).class.should == Hash
      end
    end
  end

  describe '#load' do

    #before(:each) do
    #  @c.put('_id' => 'doc0', 'msg' => 'hello world')
    #end

    it 'fails if the dump is corrupted (nothing gets loaded at all)' do

      path = File.join(File.dirname(__FILE__), 'corrupted.dump')

      lambda {
        @c.load(path)
      }.should raise_error(ArgumentError)
    end

    it 'fails if there is already a doc with the same id (nothing gets loaded at all)' do

      @c.put('_id' => 'doc0', 'msg' => 'hello world')

      path = File.join(File.dirname(__FILE__), 'test.dump')

      lambda {
        @c.load(path)
      }.should raise_error(ArgumentError)
    end

    it 'loads' do

      path = File.join(File.dirname(__FILE__), 'test.dump')

      @c.load(path)

      @c.ids.should == %w[ doc0 doc1 doc2 ]
    end

    it 'loads (leaves previous docs untouched)' do

      @c.put('_id' => 'doc-1', 'msg' => 'whatever...')

      path = File.join(File.dirname(__FILE__), 'test.dump')

      @c.load(path)

      @c.ids.should == %w[ doc-1 doc0 doc1 doc2 ]
    end

    it 'cleans and loads when :overwrite => true' do

      @c.put('_id' => 'doc-1', 'msg' => 'whatever...')

      path = File.join(File.dirname(__FILE__), 'test.dump')

      @c.load(path, :overwrite => true)

      @c.ids.should == %w[ doc0 doc1 doc2 ]
    end
  end
end



#
# specifiying rufus-jig
#
# Wed Dec  1 14:41:56 JST 2010
#

require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')


describe Rufus::Jig::Http do

  describe '.new' do

    it 'accepts ("http://127.0.0.1:5984")' do

      h = Rufus::Jig::Http.new("http://127.0.0.1:5984")

      h.scheme.should == 'http'
      h.host.should == '127.0.0.1'
      h.port.should == 5984
      h._path.should == ''
      h._query.should == nil
      h._fragment.should == nil
      h.options[:basic_auth].should == nil
    end

    it 'accepts ("http://127.0.0.1:5984/nada?a=b&c=d")' do

      h = Rufus::Jig::Http.new("http://127.0.0.1:5984/nada?a=b&c=d")

      h.scheme.should == 'http'
      h.host.should == '127.0.0.1'
      h.port.should == 5984
      h._path.should == '/nada'
      h._query.should == 'a=b&c=d'
      h._fragment.should == nil
      h.options[:basic_auth].should == nil
    end

    it "accepts ('127.0.0.1', 5984)" do

      h = Rufus::Jig::Http.new('127.0.0.1', 5984)

      h.scheme.should == 'http'
      h.host.should == '127.0.0.1'
      h.port.should == 5984
      h._path.should == ''
      h._query.should == nil
      h._fragment.should == nil
      h.options[:basic_auth].should == nil
    end

    it "accepts ('127.0.0.1', 5984, '/banana')" do

      h = Rufus::Jig::Http.new('127.0.0.1', 5984, '/banana')

      h.scheme.should == 'http'
      h.host.should == '127.0.0.1'
      h.port.should == 5984
      h._path.should == '/banana'
      h._query.should == nil
      h._fragment.should == nil
      h.options[:basic_auth].should == nil
    end

    it "accepts ('127.0.0.1', 5984, '/banana', :basic_auth => %w[ u p ])" do

      h = Rufus::Jig::Http.new(
        '127.0.0.1', 5984, '/banana', :basic_auth => %w[ u p ])

      h.scheme.should == 'http'
      h.host.should == '127.0.0.1'
      h.port.should == 5984
      h._path.should == '/banana'
      h._query.should == nil
      h._fragment.should == nil
      h.options[:basic_auth].should == %w[ u p ]
    end

    it "accepts ('http://127.0.0.1:5984', '/banana')" do

      h = Rufus::Jig::Http.new('http://127.0.0.1:5984', '/banana')

      h.scheme.should == 'http'
      h.host.should == '127.0.0.1'
      h.port.should == 5984
      h._path.should == '/banana'
      h._query.should == nil
      h._fragment.should == nil
      h.options[:basic_auth].should == nil
    end
  end
end


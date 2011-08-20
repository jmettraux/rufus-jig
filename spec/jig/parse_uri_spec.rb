# encoding: utf-8

#
# specifiying rufus-jig
#
# Tue Nov 30 15:13:43 JST 2010
#

require File.expand_path('../../spec_helper.rb', __FILE__)


describe Rufus::Jig do

  def test_parse_host

    assert_equal 'www.unifr.ch', Rufus::Jig.parse_host('http://www.unifr.ch')
    assert_equal 'mufg.jp', Rufus::Jig.parse_host('http://mufg.jp/大和')
  end

  describe '.parse_host' do

    it 'is OK with a URI without a path' do

      Rufus::Jig.parse_host('http://www.unifr.ch').should == 'www.unifr.ch'
    end

    it 'is OK with a URI with a path' do

      Rufus::Jig.parse_host('http://mufg.jp/ginkou').should == 'mufg.jp'
    end

    it 'is OK with a URI where the path is non-ASCII' do

      Rufus::Jig.parse_host('http://mufg.jp/大和').should == 'mufg.jp'
    end
  end

  describe '.parse_uri' do

    it 'returns an instance of Rufus::Jig::Uri' do

      Rufus::Jig.parse_uri('http://www.unifr.ch').class.should ==
        Rufus::Jig::Uri
    end

    it 'identifies the scheme correctly' do

      Rufus::Jig.parse_uri('http://www.unifr.ch').scheme.should == 'http'
      Rufus::Jig.parse_uri('https://www.unifr.ch').scheme.should == 'https'
    end

    it 'identifies the host correctly' do

      Rufus::Jig.parse_uri('/').host.should == nil

      Rufus::Jig.parse_uri('http://www.nada.ch').host.should == 'www.nada.ch'
      Rufus::Jig.parse_uri('https://www.nada.ch').host.should == 'www.nada.ch'
      Rufus::Jig.parse_uri('https://127.0.0.1').host.should == '127.0.0.1'
      Rufus::Jig.parse_uri('https://localhost').host.should == 'localhost'

      Rufus::Jig.parse_uri('http://www.nada.ch/a').host.should == 'www.nada.ch'
      Rufus::Jig.parse_uri('https://www.nada.ch/a').host.should == 'www.nada.ch'
      Rufus::Jig.parse_uri('https://127.0.0.1/a').host.should == '127.0.0.1'
      Rufus::Jig.parse_uri('https://localhost/a').host.should == 'localhost'
    end

    it 'identifies the port correctly' do

      Rufus::Jig.parse_uri('http://www.unifr.ch').port.should == 80
      Rufus::Jig.parse_uri('https://www.unifr.ch').port.should == 443
      Rufus::Jig.parse_uri('http://www.unifr.ch/a').port.should == 80
      Rufus::Jig.parse_uri('https://www.unifr.ch/a').port.should == 443
      Rufus::Jig.parse_uri('http://www.unifr.ch:1234').port.should == 1234
      Rufus::Jig.parse_uri('http://www.unifr.ch:1234/a').port.should == 1234
    end

    it 'identifies the path correctly' do

      Rufus::Jig.parse_uri('http://example.ch').path.should == ''
      Rufus::Jig.parse_uri('http://example.ch/a').path.should == '/a'
      Rufus::Jig.parse_uri('http://example.ch/大和').path.should == '/大和'
      Rufus::Jig.parse_uri('http://example.ch:80/a').path.should == '/a'
      Rufus::Jig.parse_uri('http://example.ch:80/a#b').path.should == '/a'
      Rufus::Jig.parse_uri('a').path.should == 'a'
      Rufus::Jig.parse_uri('a#b').path.should == 'a'
      Rufus::Jig.parse_uri('/a').path.should == '/a'
      Rufus::Jig.parse_uri('/a#b').path.should == '/a'
    end

    it 'identifies the query correctly' do

      Rufus::Jig.parse_uri('http://example.ch:80/a').query.should == nil
      Rufus::Jig.parse_uri('http://example.ch:80/a?b=c').query.should == 'b=c'
      Rufus::Jig.parse_uri('http://example.ch:80/a?b=c&d=e').query.should == 'b=c&d=e'
      Rufus::Jig.parse_uri('http://example.ch:80/a?b=c#d').query.should == 'b=c'
      Rufus::Jig.parse_uri('/a').query.should == nil
      Rufus::Jig.parse_uri('/a?b=c').query.should == 'b=c'
      Rufus::Jig.parse_uri('/a?b=c&d=e').query.should == 'b=c&d=e'
      Rufus::Jig.parse_uri('/a?b=c#d').query.should == 'b=c'
    end

    it 'identifies the fragment correctly' do

      Rufus::Jig.parse_uri('http://example.ch:80/a').fragment.should == nil
      Rufus::Jig.parse_uri('http://example.ch:80/a#b').fragment.should == 'b'
      Rufus::Jig.parse_uri('a#b').fragment.should == 'b'
      Rufus::Jig.parse_uri('/a#b').fragment.should == 'b'
      Rufus::Jig.parse_uri('a#奈良').fragment.should == '奈良'
      Rufus::Jig.parse_uri('/a#奈良').fragment.should == '奈良'
    end

    it 'identifies the user and pass correctly' do

      Rufus::Jig.parse_uri('/').username.should == nil
      Rufus::Jig.parse_uri('/').password.should == nil
      Rufus::Jig.parse_uri('http://example.ch:80/a').username.should == nil
      Rufus::Jig.parse_uri('http://example.ch:80/a').password.should == nil

      Rufus::Jig.parse_uri('http://a:b@example.ch:80/a').username.should == 'a'
      Rufus::Jig.parse_uri('http://a:b@example.ch:80/a').password.should == 'b'
    end
  end
end

describe Rufus::Jig::Uri do

  describe '#to_s' do

    it "flips burgers" do

      s = Rufus::Jig.parse_uri('http://example.ch:80/a').to_s.should ==
        'http://example.ch:80/a'
    end
  end

  describe '#tail_to_s' do
  end
end


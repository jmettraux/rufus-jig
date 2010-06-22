# encoding: utf-8

#
# testing rufus-jig
#
# Tue Jun 22 12:31:35 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')


class UtParseUriTest < Test::Unit::TestCase

  def test_parse_host

    assert_equal 'www.unifr.ch', Rufus::Jig.parse_host('http://www.unifr.ch')
    assert_equal 'mufg.jp', Rufus::Jig.parse_host('http://mufg.jp/大和')
  end

  def test_parse_uri

    assert_equal(
      'www.unifr.ch',
      Rufus::Jig.parse_uri('http://www.unifr.ch').host)
    assert_equal(
      'www.unifr.ch',
       Rufus::Jig.parse_uri('http://www.unifr.ch/').host)
    assert_equal(
      'mufg.jp',
       Rufus::Jig.parse_uri('http://mufg.jp/大和').host)
    assert_equal(
      '8080',
       Rufus::Jig.parse_uri('http://mufg.jp:8080/大和').port)
    assert_equal(
      '/大和',
       Rufus::Jig.parse_uri('http://mufg.jp:8080/大和').path)
    assert_equal(
      'nada=surf&rock=roll',
       Rufus::Jig.parse_uri('http://mufg.jp:8080/大和?nada=surf&rock=roll').query)
    assert_equal(
      '脳=電',
       Rufus::Jig.parse_uri('http://mufg.jp:8080/大和?脳=電').query)
  end

  def test_parse_uri_with_path

    assert_equal(
      nil,
      Rufus::Jig.parse_uri('/').host)
  end
end



#
# testing rufus-jig
#
# Wed Feb 24 17:29:39 JST 2010
#

require File.join(File.dirname(__FILE__), 'couch_base')


class CtAttachmentsTest < Test::Unit::TestCase

  def setup

    h = Rufus::Jig::Http.new('127.0.0.1', 5984)
    begin
      h.delete('/rufus_jig_test')
    rescue Exception => e
      #p e
    end

    h.put('/rufus_jig_test', '')
    h.close

    @c = Rufus::Jig::Couch.new('127.0.0.1', 5984, 'rufus_jig_test')

    @c.put('_id' => 'thedoc', 'function' => 'recipient for attachements')
    @d = @c.get('thedoc')
  end

  def teardown

    @c.close
  end

  def test_missing_content_type

    assert_raise ArgumentError do

      @c.attach(
        'thedoc/message', 'this is a message', :content_type => 'text/plain')
    end
  end

  def test_attach

    r = @c.attach(
      'thedoc', @d['_rev'], 'message', 'this is a message',
      :content_type => 'text/plain')

    assert_not_equal @d['_rev'], r['_rev']

    assert_equal 'this is a message', @c.get('thedoc/message')

    assert_not_equal @d['_rev'], @c.get('thedoc')['_rev']

    r = @c.http.get('/rufus_jig_test/thedoc/message', :raw => true)

    assert_equal 200, r.status
    assert_equal 'text/plain', r.headers['Content-Type']
  end

  def test_attach_with_doc

    @c.attach(
      @d, 'message', 'this is a message', :content_type => 'text/plain')

    assert_equal 'this is a message', @c.get('thedoc/message')
  end

  def test_wrong_rev_on_attach

    assert_raise Rufus::Jig::HttpError do
      @c.attach(
        'thedoc', '1-745aeb1d8eccafa88e635b813507608c',
        'message', 'this is a message',
        :content_type => 'text/plain')
    end
  end

  def test_attach_image

    image = File.read(File.join(File.dirname(__FILE__), 'tweet.png'))

    @c.attach(
      'thedoc', @d['_rev'], 'image', image, :content_type => 'image/png')

    r = @c.http.get('/rufus_jig_test/thedoc/image', :raw => true)

    assert_equal 200, r.status
    assert_equal 'image/png', r.headers['Content-Type']

    #File.open('out.png', 'wb') { |f| f.write(r.body) }
  end

  def test_detach

    attach_image

    d = @c.get('thedoc')

    r = @c.detach('thedoc', d['_rev'], 'image')

    assert_not_equal d['_rev'], r['_rev']

    assert_nil @c.get('thedoc/image')
  end

  def test_detach_fail

    attach_image

    assert_equal true, @c.detach(@d, 'image')
  end

  protected

  def attach_image

    image = File.read(File.join(File.dirname(__FILE__), 'tweet.png'))

    @c.attach(
      'thedoc', @d['_rev'], 'image', image, :content_type => 'image/png')
  end
end


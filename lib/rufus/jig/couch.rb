#--
# Copyright (c) 2009-2010, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


module Rufus::Jig

  #
  # A class wrapping an instance of Rufus::Jig::Http and providing
  # CouchDB-oriented http verbs.
  #
  class Couch

    attr_reader :http

    def initialize (*args)

      @http, @path, payload, @opts = Rufus::Jig::Http.extract_http(false, *args)

      @path ||= '/'
    end

    def close

      @http.close
    end

    def put (doc_or_path, opts={})

      path, payload = if doc_or_path.is_a?(String)
        [ doc_or_path, '' ]
      else
        [ doc_or_path['_id'], doc_or_path ]
      end

      pa = adjust(path)

      if @opts[:re_put_ok] == false && payload['_rev']
        rr = delete(path, payload['_rev'])
        return rr unless rr.nil?
      end

      r = @http.put(pa, payload, :content_type => :json, :cache => false)

      return @http.get(pa) if r == true
        # conflict

      if opts[:update_rev] && doc_or_path.is_a?(Hash)
        doc_or_path['_rev'] = r['rev']
      end

      nil
    end

    def get (doc_or_path, opts={})

      path = doc_or_path.is_a?(Hash) ? doc_or_path['_id'] : doc_or_path
      path = adjust(path)

      if et = etag(path)
        opts[:etag] = et
      end

      @http.get(path, opts)
    end

    def delete (doc_or_path, rev=nil)

      doc, path, rev = if rev
        [ { '_id' => doc_or_path, '_rev' => rev }, doc_or_path ]
      elsif doc_or_path.is_a?(String)
        [ nil, doc_or_path ]
      else
        [ doc_or_path, doc_or_path['_id'] ]
      end

      path = adjust(path)

      r = if doc

        raise(
          ArgumentError.new("cannot delete document without _rev")
        ) unless doc['_rev']

        rpath = Rufus::Jig::Path.add_params(path, :rev => doc['_rev'])

        @http.delete(rpath)

      else

        @http.delete(path)
      end

      if r == true # conflict

        doc = @http.get(path)
        doc ? doc : true
          # returns the doc if present or true if the doc is gone

      else # delete is successful

        nil
      end
    end

    def post (path, doc)

      path = adjust(path)

      opts = { :content_type => :json }

      if et = etag(path)
        opts[:etag] = et
      end

      @http.post(path, doc, opts)
    end

    # Attaches a file to a couch document.
    #
    #   couch.attach(
    #     doc['_id'], doc['_rev'], 'my_picture', data,
    #     :content_type => 'image/jpeg')
    #
    # or
    #
    #   couch.attach(
    #     doc, 'my_picture', data,
    #     :content_type => 'image/jpeg')
    #
    def attach (doc_id, doc_rev, attachment_name, data, opts=nil)

      if opts.nil?
        opts = data
        data = attachment_name
        attachment_name = doc_rev
        doc_rev = doc_id['_rev']
        doc_id = doc_id['_id']
      end

      attachment_name = attachment_name.gsub(/\//, '%2F')

      ct = opts[:content_type]

      raise(ArgumentError.new(
        ":content_type option must be specified"
      )) unless ct

      opts[:cache] = false

      path = adjust("#{doc_id}/#{attachment_name}?rev=#{doc_rev}")

      if @http.variant == :patron
        #
        # patron, as of 0.4.5 has difficulties when PUTting attachements
        # this is a fallback to net/http
        #
        require 'net/http'
        http = Net::HTTP.new(@http.host, @http.port)
        req = Net::HTTP::Put.new(path)
        req['User-Agent'] =
          "rufus-jig #{Rufus::Jig::VERSION} (patron 0.4.5 fallback to net/http)"
        req['Content-Type'] =
          opts[:content_type]
        req.body = data
        res = http.start { |h| h.request(req) }
        status = res.code.to_i
        raise Rufus::Jig::HttpError.new(status, res.body) \
          unless [ 200, 201 ].include?(status)
        return nil
      end

      @http.put(path, data, opts)
    end

    # Detaches a file from a couch document.
    #
    #   couch.detach(doc['_id'], doc['_rev'], 'my_picture')
    #
    # or
    #
    #   couch.detach(doc, 'my_picture')
    #
    def detach (doc_id, doc_rev, attachment_name=nil)

      if attachment_name.nil?
        attachment_name = doc_rev
        doc_rev = doc_id['_rev']
        doc_id = doc_id['_id']
      end

      attachment_name = attachment_name.gsub(/\//, '%2F')

      path = adjust("#{doc_id}/#{attachment_name}?rev=#{doc_rev}")

      @http.delete(path)
    end

    protected

    def adjust (path)

      case path
        when '.' then @path
        when /^\// then path
        else Rufus::Jig::Path.join(@path, path)
      end
    end

    # Fetches etag from http cache
    #
    def etag (path)

      r = @http.cache[path]

      r ? r.first : nil
    end
  end
end


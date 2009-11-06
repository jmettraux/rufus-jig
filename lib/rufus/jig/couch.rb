#--
# Copyright (c) 2009-2009, John Mettraux, jmettraux@gmail.com
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

  class CouchError < HttpError

    # the original error hash
    #
    attr_reader :original

    def initialize (status, message)

      @original = (Rufus::Jig::Json.decode(message) rescue nil) || message

      if @original.is_a?(String)
        super(status, @original)
      else
        super(status, "#{@original['error']}: #{@original['reason']}")
      end
    end
  end

  class CouchResource

    # the jig client, the CouchThing uses
    #
    attr_reader :http

    # the path for this couch resource
    #
    attr_reader :path

    def initialize (http, path)

      @http = http
      @path = path
    end

    def get (path, opts={})
      @http.get(adjust(path), opts)
    end
    def post (path, data, opts={})
      @http.post(adjust(path), data, opts)
    end
    def delete (path, opts={})
      @http.delete(adjust(path), opts)
    end
    def put (path, data, opts={})
      @http.put(adjust(path), data, opts)
    end

    # Returns an array of 1 or more UUIDs generated by CouchDB.
    #
    def get_uuids (count=1)

      @http.get("/_uuids?count=#{count}")['uuids']
    end

    def get_databases

      @http.get('/_all_dbs')
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

  class Couch < CouchResource

    def initialize (host, port, options={})

      options.merge!(:error_class => CouchError)

      super(Rufus::Jig::Http.new(host, port, options), '/')
    end

    def get_db (name)

      return nil if get(name).nil?

      CouchDatabase.new(self, name)
    end

    def put_db (name)

      d = CouchDatabase.new(self, name)
      d.put('.', '')

      d
    end

    def delete_db (name)

      raise(ArgumentError.new("no db named '#{name}'")) if get(name).nil?

      delete(name)
    end
  end

  class CouchDatabase < CouchResource

    attr_reader :couch
    attr_reader :name

    def initialize (couch, name)

      @couch = couch
      @name = name

      super(couch.http, Rufus::Jig::Path.join(couch.path, @name))
    end

    def put_doc (i, doc)

      info = put(i, doc, :content_type => :json, :cache => false)

      doc = Rufus::Jig.marshal_copy(doc)
      doc['_id'] = info['id']
      doc['_rev'] = info['rev']

      CouchDocument.new(self, doc)
    end

    def get_doc (i)

      path = Rufus::Jig::Path.join(@path, i)
      opts = {}

      if et = etag(path)
        opts[:etag] = et
      end

      doc = get(path, opts)

      doc ? CouchDocument.new(self, doc) : nil
    end

    def delete_doc (i, rev)

      raise(ArgumentError.new("no doc '#{name}'")) if get(i).nil?

      delete(Rufus::Jig::Path.add_params(i, :rev => rev))
    end
  end

  class CouchDocument < CouchResource

    attr_reader :hash

    def initialize (db, h)

      super(db.http, Rufus::Jig::Path.join(db.path, h['_id']))
      @hash = h
    end

    def [] (k)
      @hash[k]
    end

    def []= (k, v)
      @hash[k] = v
    end

    def _id
      @hash['_id']
    end

    def _rev
      @hash['_rev']
    end

    def get

      h = super(@path, :etag => "\"#{@hash['_rev']}\"")

      raise(CouchError.new(410, 'probably gone')) unless h

      @hash = h

      self
    end

    def delete

      super(Rufus::Jig::Path.add_params(@path, :rev => _rev))
    end

    def put

      h = super(
        @path, @hash, :content_type => :json, :etag => "\"#{@hash['_rev']}\"")

      @hash['_rev'] = h['rev']
    end
  end
end


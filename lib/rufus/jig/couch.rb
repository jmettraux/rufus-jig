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

  class Couch

    attr_reader :http

    def initialize (*args)

      @http, @path, payload, @opts = Rufus::Jig::Http.extract_http(false, *args)

      @path ||= '/'
    end

    def put (doc_or_path, opts={})

      path, payload = if doc_or_path.is_a?(String)
        [ doc_or_path, '' ]
      else
        [ doc_or_path['_id'], doc_or_path ]
      end

      path = adjust(path)

      begin

        r = @http.put(path, payload, :content_type => :json, :cache => false)

        doc_or_path['_rev'] = r['rev'] \
          if opts[:update_rev] && doc_or_path.is_a?(Hash)

        nil

      rescue Rufus::Jig::HttpError => he

        if he.status == 409
          true
        else
          raise he
        end
      end
    end

    def get (doc_or_path)

      path = doc_or_path.is_a?(Hash) ? doc_or_path['_id'] : doc_or_path
      path = adjust(path)

      opts = {}

      if et = etag(path)
        opts[:etag] = et
      end

      @http.get(path, opts)
    end

    def delete (doc_or_path, rev=nil)

      doc_or_path = { '_id' => doc_or_path, '_rev' => rev } if rev

      begin

        if doc_or_path.is_a?(String)
          @http.delete(adjust(doc_or_path))
        else
          path = adjust(doc_or_path['_id'])
          path = Rufus::Jig::Path.add_params(path, :rev => doc_or_path['_rev'])
          @http.delete(path)
        end

        nil

      rescue Rufus::Jig::HttpError => he

        if he.status == 409
          true
        else
          raise he
        end
      end
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

# =============================================================================
# BAK
# =============================================================================

#  #
#  # An error class for the couch stuff.
#  #
#  # Has a #status and an #original methods.
#  #
#  class CouchError < HttpError
#
#    # the original error hash
#    #
#    attr_reader :original
#
#    def initialize (status, message)
#
#      @original = (Rufus::Jig::Json.decode(message) rescue nil) || message
#
#      if @original.is_a?(String)
#        super(status, @original)
#      else
#        super(status, "#{@original['error']}: #{@original['reason']}")
#      end
#    end
#  end
#
#  #
#  # The parent class of Rufus::Jig::Couch CouchDatabase and CouchDocument.
#  #
#  class CouchResource
#
#    # the jig client
#    #
#    attr_reader :http
#
#    # the path for this couch resource
#    #
#    attr_reader :path
#
#    # nil for a Couch instance, the Couch instance for a CouchDatabase or
#    # the CouchDatabase for a CouchDocument.
#    #
#    attr_reader :parent
#
#    def initialize (parent_or_http, path)
#
#      @path = path
#
#      path = path.split('/').select { |e| e != '' }
#
#      @parent, @http = if parent_or_http.is_a?(Rufus::Jig::Http)
#
#        parent = if path.length == 0
#          nil
#        elsif path.length == 1
#          Couch.new(parent_or_http)
#        else
#          CouchDatabase.new(parent_or_http, path.first)
#        end
#        [ parent, parent_or_http ]
#
#      else
#
#        [ parent_or_http, parent_or_http.http ]
#      end
#
#      @http.options[:error_class] = CouchError
#    end
#
#    # Returns the Rufus::Jig::Couch instance holding this couch resource.
#    #
#    def couch
#
#      @parent == nil ? self : @parent.couch
#    end
#
#    # Returns the Rufus::Jig::CouchDatabase instance holding this couch
#    # resource (or nil if this resource is a Rufus::Jig::Couch instance).
#    #
#    def db
#
#      return nil if @parent.nil?
#      return self if self.is_a?(CouchDatabase)
#      @parent # self is a document
#    end
#
#    # GET, relatively to this resource.
#    #
#    def get (path, opts={})
#      @http.get(adjust(path), opts)
#    end
#
#    # POST, relatively to this resource.
#    #
#    def post (path, data, opts={})
#      @http.post(adjust(path), data, opts)
#    end
#
#    # DELETE, relatively to this resource.
#    #
#    def delete (path, opts={})
#      @http.delete(adjust(path), opts)
#    end
#
#    # PUT, relatively to this resource.
#    #
#    def put (path, data, opts={})
#      @http.put(adjust(path), data, opts)
#    end
#
#    # Returns an array of 1 or more UUIDs generated by CouchDB.
#    #
#    def get_uuids (count=1)
#
#      @http.get("/_uuids?count=#{count}")['uuids']
#    end
#
#    # Returns the list of all database [names] in this couch.
#    #
#    def get_databases
#
#      @http.get('/_all_dbs')
#    end
#
#    protected
#
#    def adjust (path)
#
#      case path
#        when '.' then @path
#        when /^\// then path
#        else Rufus::Jig::Path.join(@path, path)
#      end
#    end
#
#    # Fetches etag from http cache
#    #
#    def etag (path)
#
#      r = @http.cache[path]
#
#      r ? r.first : nil
#    end
#  end
#
#  #
#  # Wrapping info about a Couch server.
#  #
#  #
#  # Also provides a set of class methods for interacting directly with couch
#  # resources.
#  #
#  # * get_couch
#  # * get_db
#  # * put_db
#  # * delete_db
#  # * get_doc
#  # * put_doc
#  # * delete_doc
#  #
#  # The first one is very important
#  #
#  class Couch < CouchResource
#
#    # Never call this method directly.
#    #
#    # Do
#    #
#    #  couch = Rufus::Jig::Couch.get_couch('127.0.0.1', 5984)
#    #
#    # instead.
#    #
#    def initialize (parent_or_http)
#
#      super(parent_or_http, '/')
#    end
#
#    # Returns a CouchDatabase instance or nil if the database doesn't
#    # exist in this couch.
#    #
#    #  couch = Rufus::Jig::Couch.get_couch('127.0.0.1', 5984)
#    #  db = couch.get_db('hr_documents')
#    #
#    def get_db (name)
#
#      return nil if get(name).nil?
#
#      CouchDatabase.new(couch, name)
#    end
#
#    # Creates a database and returns the new CouchDatabase instance.
#    #
#    # Will raise a Rufus::Jig::CouchError if the db already exists.
#    #
#    #  couch = Rufus::Jig::Couch.get_couch('127.0.0.1', 5984)
#    #  db = couch.put_db('financial_results')
#    #
#    def put_db (name)
#
#      d = CouchDatabase.new(couch, name)
#      d.put('.', '')
#
#      d
#    end
#
#    # Deletes a database, given its name.
#    #
#    # Will raise a Rufus::Jig::CouchError if the db doesn't exist.
#    #
#    #  couch = Rufus::Jig::Couch.get_couch('127.0.0.1', 5984)
#    #  db = couch.delete_db('financial_results')
#    #
#    def delete_db (name)
#
#      raise(CouchError.new(404, "no db named '#{name}'")) if get(name).nil?
#
#      delete(name)
#    end
#
#    #--
#    # handy class methods
#    #++
#
#    # Returns a Rufus::Jig::Couch instance.
#    #
#    #   couch = Rufus::Jig::Couch.get_couch('http://127.0.0.1:5984')
#    #     # or
#    #   couch = Rufus::Jig::Couch.get_couch('127.0.0.1', 5984)
#    #
#    # Will raise a Rufus::Jig::CouchError in case of trouble.
#    #
#    def self.get_couch (*args)
#
#      ht, pt, pl, op = extract_http(false, *args)
#
#      Couch.new(ht)
#    end
#
#    # Returns a CouchDatabase instance or nil if the db doesn't exist.
#    #
#    #   db = Rufus::Jig::Couch.get_db('127.0.0.1', 5984, 'my_database')
#    #     # or
#    #   db = Rufus::Jig::Couch.get_db('http://127.0.0.1:5984/my_database')
#    #
#    def self.get_db (*args)
#
#      ht, pt, pl, op = extract_http(false, *args)
#
#      return nil unless ht.get(pt)
#
#      CouchDatabase.new(ht, Rufus::Jig::Path.to_name(pt))
#    end
#
#    # Creates a database and returns a CouchDatabase instance.
#    #
#    #   db = Rufus::Jig::Couch.put_db('127.0.0.1', 5984, 'my_database')
#    #     # or
#    #   db = Rufus::Jig::Couch.put_db('http://127.0.0.1:5984/my_database')
#    #
#    # Will raise a Rufus::Jig::CouchError if the db already exists.
#    #
#    def self.put_db (*args)
#
#      ht, pt, pl, op = extract_http(false, *args)
#
#      ht.put(pt, '')
#
#      CouchDatabase.new(ht, Rufus::Jig::Path.to_name(pt))
#    end
#
#    # Deletes a database.
#    #
#    #   Rufus::Jig::Couch.delete_db('127.0.0.1', 5984, 'my_database')
#    #     # or
#    #   Rufus::Jig::Couch.delete_db('http://127.0.0.1:5984/my_database')
#    #
#    # Will raise a Rufus::Jig::CouchError if the db doesn't exist.
#    #
#    def self.delete_db (*args)
#
#      ht, pt, pl, op = extract_http(false, *args)
#
#      ht.delete(pt)
#    end
#
#    # Fetches a document. Returns nil if not found or a CouchDocument instance.
#    #
#    #   Rufus::Jig::Couch.get_doc('127.0.0.1', 5984, 'my_database/doc0')
#    #     # or
#    #   Rufus::Jig::Couch.get_doc('http://127.0.0.1:5984/my_database/doc0')
#    #
#    def self.get_doc (*args)
#
#      ht, pt, pl, op = extract_http(false, *args)
#
#      doc = ht.get(pt)
#
#      doc ? CouchDocument.new(ht, pt, doc) : nil
#    end
#
#    # Puts (creates) a document
#    #
#    #   Rufus::Jig::Couch.put_doc(
#    #     '127.0.0.1', 5984, 'my_database/doc0', { 'a' => 'b' })
#    #       # or
#    #   Rufus::Jig::Couch.put_doc(
#    #     'http://127.0.0.1:5984/my_database/doc0', { 'x' => 'y' })
#    #
#    # To update a doc, get it first, then change its content and put it
#    # via its put method.
#    #
#    def self.put_doc (*args)
#
#      ht, pt, pl, op = extract_http(true, *args)
#
#      info = ht.put(pt, pl, :content_type => :json, :cache => false)
#
#      CouchDocument.new(ht, pt, Rufus::Jig.marshal_copy(pl), info)
#    end
#
#    # Deletes a document.
#    #
#    #   Rufus::Jig::Couch.delete_doc('127.0.0.1', 5984, 'my_database/doc0')
#    #     # or
#    #   Rufus::Jig::Couch.delete_doc('http://127.0.0.1:5984/my_database/doc0')
#    #
#    # Will raise a Rufus::Jig::CouchError if the doc doesn't exist.
#    #
#    def self.delete_doc (*args)
#
#      ht, pt, pl, op = extract_http(false, *args)
#
#      ht.delete(pt)
#    end
#
#    # This method is used from get_couch, get_db, put_db and co...
#    #
#    # Never used directly.
#    #
#    def self.extract_http (payload_expected, *args)
#
#      a = Rufus::Jig::Http.extract_http(payload_expected, *args)
#
#      a.first.error_class = Rufus::Jig::CouchError
#
#      a
#    end
#  end
#
#  #
#  # Wrapping info about a Couch database.
#  #
#  # You usually grab an instance of it like that :
#  #
#  #   db = Rufus::Jig::Couch.get_db('127.0.0.1', 5984, 'my_database')
#  #     # or
#  #   db = Rufus::Jig::Couch.get_db('http://127.0.0.1:5984/my_database')
#  #
#  #     # or
#  #   couch = Rufus::Jig::Couch.get_couch('127.0.0.1', 5984)
#  #   db = Rufus::Jig::Couch.get_db('my_database')
#  #
#  class CouchDatabase < CouchResource
#
#    attr_reader :name
#
#    # Usually called via Couch#get_database(name)
#    #
#    def initialize (parent_or_http, name)
#
#      @name = name
#
#      super(parent_or_http, Rufus::Jig::Path.to_path(@name))
#    end
#
#    # Given an id and an JSONable hash, puts the doc to the database
#    # and returns a CouchDocument instance wrapping it.
#    #
#    #   db.put_doc('doc0', { 'item' => 'car', 'brand' => 'bmw' })
#    #
#    # or
#    #
#    #   db.put_doc('_id' => 'doc0', 'item' => 'car', 'brand' => 'bmw')
#    #
#    def put_doc (doc_id, doc=nil)
#
#      if doc.nil?
#        doc = doc_id
#        doc_id = doc['_id']
#      end
#
#      info = put(doc_id, doc, :content_type => :json, :cache => false)
#
#      CouchDocument.new(
#        self,
#        Rufus::Jig::Path.join(@name, doc_id),
#        Rufus::Jig.marshal_copy(doc), info)
#    end
#
#    # Gets a document, given its id.
#    # (conditional GET).
#    #
#    #   db.get_doc('doc0')
#    #
#    def get_doc (doc_id)
#
#      path = Rufus::Jig::Path.join(@path, doc_id)
#      opts = {}
#
#      if et = etag(path)
#        opts[:etag] = et
#      end
#
#      doc = get(path, opts)
#
#      doc ?
#        CouchDocument.new(self, Rufus::Jig::Path.join(@name, doc_id), doc) :
#        nil
#    end
#
#    # Deletes a document, you have to provide the current revision.
#    #
#    #   db.delete_doc('doc0')
#    #
#    def delete_doc (doc_id, rev)
#
#      raise(ArgumentError.new("no doc '#{name}'")) if get(doc_id).nil?
#
#      delete(Rufus::Jig::Path.add_params(doc_id, :rev => rev))
#    end
#  end
#
#  #
#  # Wrapping a couch document.
#  #
#  # Responds to [] and []=
#  #
#  class CouchDocument < CouchResource
#
#    attr_reader :payload
#
#    # Don't call this method directly, use one of the get_doc or put_doc
#    # methods.
#    #
#    def initialize (parent_or_http, path, doc, put_result=nil)
#
#      super(parent_or_http, path)
#      @payload = doc
#
#      if put_result
#        @payload['_id'] = put_result['id']
#        @payload['_rev'] = put_result['rev']
#      end
#    end
#
#    # Gets a value.
#    #
#    def [] (k)
#      @payload[k]
#    end
#
#    # Sets a value.
#    #
#    def []= (k, v)
#      @payload[k] = v
#    end
#
#    # Returns to CouchDB id of the document.
#    #
#    def _id
#      @payload['_id']
#    end
#
#    # Returns the revision string for this copy of the document.
#    #
#    def _rev
#      @payload['_rev']
#    end
#
#    # Re-gets this document (updating its _rev and content if necessary).
#    #
#    def get
#
#      opts = {}
#
#      if @payload && rev = @payload['_rev']
#        opts[:etag] = "\"#{rev}\""
#      end
#
#      h = super(@path, opts)
#
#      raise(CouchError.new(410, 'probably gone')) unless h
#
#      @payload = h
#
#      self
#    end
#
#    # Deletes this document (from Couch).
#    #
#    def delete
#
#      super(Rufus::Jig::Path.add_params(@path, :rev => _rev))
#    end
#
#    # Puts this document (assumes you have updated it).
#    #
#    def put
#
#      h = super(
#        @path, @payload,
#        :content_type => :json, :etag => "\"#{@payload['_rev']}\"")
#
#      @payload['_rev'] = h['rev']
#    end
#  end
end


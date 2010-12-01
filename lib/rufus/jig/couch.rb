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

require 'base64'
require 'socket'
  # for #on_change


module Rufus::Jig

  #
  # A class wrapping an instance of Rufus::Jig::Http and providing
  # CouchDB-oriented http verbs.
  #
  class Couch

    attr_reader :path
    attr_reader :http

    def initialize(*args)

      @http = Rufus::Jig::Http.new(*args)

      @path = @http._path || '/'
    end

    def name

      path
    end

    def close

      @http.close
    end

    def put(doc_or_path, opts={})

      path, payload = if doc_or_path.is_a?(String)
        [ doc_or_path, '' ]
      else
        [ doc_or_path['_id'], doc_or_path ]
      end

      pa = adjust(path)

      #if @opts[:re_put_ok] == false && payload['_rev']
      #  rr = delete(path, payload['_rev'])
      #  return rr unless rr.nil?
      #end

      r = @http.put(pa, payload, :content_type => :json, :cache => false)

      return @http.get(pa) || true if r == true
        #
        # conflict : returns the current version of the doc
        # (or true if there is no document (probably 404 for the database))

      if opts[:update_rev] && doc_or_path.is_a?(Hash)
        doc_or_path['_rev'] = r['rev']
      end

      nil
    end

    def get(doc_or_path, opts={})

      path = doc_or_path.is_a?(Hash) ? doc_or_path['_id'] : doc_or_path
      path = adjust(path)

      @http.get(path, opts)
    end

    def delete(doc_or_path, rev=nil)

      doc, path = if rev
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

    def post(path, doc)

      @http.post(adjust(path), doc, :content_type => :json)
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
    def attach(doc_id, doc_rev, attachment_name, data, opts=nil)

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

        # patron, as of 0.4.5 (~> 0.4.10), has difficulties when PUTting
        # attachements
        # this is a fallback to net/http

        require 'net/http'

        http = Net::HTTP.new(@http.host, @http.port)

        req = Net::HTTP::Put.new(path)
        req['User-Agent'] =
          "rufus-jig #{Rufus::Jig::VERSION} (patron 0.4.x fallback to net/http)"
        req['Content-Type'] =
          opts[:content_type]
        req['Accept'] =
          'application/json'
        req.body = data

        res = Rufus::Jig::HttpResponse.new(http.start { |h| h.request(req) })

        return @http.send(:respond, :put, path, opts, nil, res)
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
    def detach(doc_id, doc_rev, attachment_name=nil)

      if attachment_name.nil?
        attachment_name = doc_rev
        doc_rev = doc_id['_rev']
        doc_id = doc_id['_id']
      end

      attachment_name = attachment_name.gsub(/\//, '%2F')

      path = adjust("#{doc_id}/#{attachment_name}?rev=#{doc_rev}")

      @http.delete(path)
    end

    # Watches the database for changes.
    #
    #   db.on_change do |doc_id, deleted|
    #     puts "doc #{doc_id} has been #{deleted ? 'deleted' : 'changed'}"
    #   end
    #
    #   db.on_change do |doc_id, deleted, doc|
    #     puts "doc #{doc_id} has been #{deleted ? 'deleted' : 'changed'}"
    #     p doc
    #   end
    #
    # This is a blocking method. One might want to wrap it inside of a Thread.
    #
    # Note : doc inclusion (third parameter to the block) only works with
    # CouchDB >= 0.11.
    #
    def on_change(opts={}, &block)

      query = {
        'feed' => 'continuous',
        'heartbeat' => opts[:heartbeat] || 20_000 }
        #'since' => 0 } # that's already the default
      query['include_docs'] = true if block.arity > 2
      query = query.map { |k, v| "#{k}=#{v}" }.join('&')

      socket = TCPSocket.open(@http.host, @http.port)

      auth = @http.options[:basic_auth]

      if auth
        auth = Base64.encode64(auth.join(':')).strip
        auth = "Authorization: Basic #{auth}\r\n"
      else
        auth = ''
      end

      socket.print("GET /#{path}/_changes?#{query} HTTP/1.1\r\n")
      socket.print("User-Agent: rufus-jig #{Rufus::Jig::VERSION}\r\n")
      #socket.print("Accept: application/json;charset=UTF-8\r\n")
      socket.print(auth)
      socket.print("\r\n")

      # consider reply

      answer = socket.gets.strip
      status = answer.match(/^HTTP\/.+ (\d{3}) /)[1].to_i

      raise Rufus::Jig::HttpError.new(status, answer) if status != 200

      # discard headers

      loop do
        data = socket.gets
        break if data.nil? || data == "\r\n"
      end

      # the on_change loop

      loop do
        data = socket.gets
        break if data.nil?
        data = (Rufus::Json.decode(data) rescue nil)
        next unless data.is_a?(Hash)
        args = [ data['id'], (data['deleted'] == true) ]
        args << data['doc'] if block.arity > 2
        block.call(*args)
      end

      on_change(opts, &block) if opts[:reconnect]
    end

    DESIGN_PATH_REGEX = /^\_design\//

    # A development method. Removes all the design documents in this couch
    # database.
    #
    # Used in tests setup or teardown, when views are subject to frequent
    # changes (rufus-doric and co).
    #
    def nuke_design_documents

      docs = get('_all_docs')['rows']

      views = docs.select { |d| d['id'] && DESIGN_PATH_REGEX.match(d['id']) }

      views.each { |v| delete(v['id'], v['value']['rev']) }
    end

    KEYS = [ :key, :startkey, :endkey ]

    # TODO : document me !
    #
    def query(path, opts={})

      raw = opts.delete(:raw)

      path = if DESIGN_PATH_REGEX.match(path)
        path
      else
        doc_id, view = path.split(':')
        path = "_design/#{doc_id}/_view/#{view}"
      end

      path = adjust(path)

      keys = opts.delete(:keys)

      KEYS.each do |key|
        if value = opts[key]
          opts[key] = Rufus::Json.encode(value)
        end
      end

      path = if opts.empty?
        path
      else
        "#{path}?#{opts.collect { |k, v| "#{k}=#{v}" }.join('&') }"
      end

      res = if keys
        opts[:cache] = true if opts[:cache].nil?
        @http.post(path, { 'keys' => keys }, opts)
      else
        @http.get(path, opts)
      end

      return res if raw

      res.nil? ? res : res['rows']
    end

    protected

    def adjust(path)

      case path
        when '.' then @path
        when /^\// then path
        else Rufus::Jig::Path.join(@path, path)
      end
    end
  end
end


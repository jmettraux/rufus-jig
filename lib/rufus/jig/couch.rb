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

    def close

      @http.close
    end

    def put (doc_or_path, opts={})

      path, payload = if doc_or_path.is_a?(String)
        [ doc_or_path, '' ]
      else
        [ doc_or_path['_id'], doc_or_path ]
      end

      if @opts[:re_put_ok] == false && payload['_rev']
        cur = get(path)
        return true if cur.nil?
        return cur if cur['_rev'] != payload['_rev']
      end

      path = adjust(path)

      r = @http.put(path, payload, :content_type => :json, :cache => false)

      return true if r == true
        # conflict

      if opts[:update_rev] && doc_or_path.is_a?(Hash)
        doc_or_path['_rev'] = r['rev']
      end

      nil
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

      r = if doc_or_path.is_a?(String)

        @http.delete(adjust(doc_or_path))

      else

        raise(
          ArgumentError.new("cannot delete document without _rev")
        ) unless doc_or_path['_rev']

        path = adjust(doc_or_path['_id'])
        path = Rufus::Jig::Path.add_params(path, :rev => doc_or_path['_rev'])

        @http.delete(path)
      end

      r == true ? true : nil
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


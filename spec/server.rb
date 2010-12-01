# encoding: utf-8

log = File.open('server.log', 'wb')
STDOUT.reopen(log)
STDERR.reopen(log)


# a test sinata server

require 'rubygems'
require 'sinatra'
require 'json'


# change the port here if needed

set :port, 4567


#
# BASIC
#

get '/' do

  content_type 'text/plain'

  'hello'
end

get '/document' do

  content_type 'application/json'

  '{"car":"Mercedes-Benz"}'
end

get '/document_accept' do

  if env['HTTP_ACCEPT'] == 'application/json'
    content_type 'application/json'
  else
    content_type 'text/plain'
  end

  '{"car":"Saab"}'
end

get '/document_json_plain' do

  content_type 'text/plain'

  '{"car":"Peugeot"}'
end

get '/document_utf8' do

  content_type 'application/json', :charset => 'utf-8'

  '{"car":"トヨタ"}'
end

get '/document_with_etag' do

  etag = '"123456123456"'

  if env['HTTP_IF_NONE_MATCH'] == etag

    halt 304, 'not modified'

  else

    content_type 'application/json'
    response['Etag'] = '"123456123456"'

    '{"car":"Peugeot"}'
  end
end

get '/server_error' do

  halt 500, 'internal server error'
end

get '/params' do

  content_type 'application/json'
  params.to_json
end


#
# DOCUMENTS
#

DOCS = {}

get '/documents' do

  content_type 'application/json'

  DOCS.to_json
end

post '/documents' do

  #p env

  did = (Time.now.to_f * 1000).to_i.to_s
  doc = env['rack.input'].read

  DOCS[did] = [ request.content_type, doc ]

  response.status = 201
  response['Location'] = "/documents/#{did}"

  if params[:mirror] || params[:etag]
    response['Etag'] = "\"#{did}\"" if params[:etag]
    content_type request.content_type
    doc
  else
    'created.'
  end
end

put '/documents/:id' do

  #p env

  doc = env['rack.input'].read

  DOCS[params[:id]] = [ request.content_type, doc ]

  response.status = 201

  if params[:mirror] || params[:etag]
    response['Etag'] = "\"#{params[:id]}\"" if params[:etag]
    content_type request.content_type || 'text/plain'
    doc
  else
    'created.'
  end
end

put '/conflict' do

  response.status = 409

  'conflict'
end

get '/documents/:id' do

  if doc = DOCS[params[:id]]

    content_type doc.first

    doc.last
  else

    halt 404, { 'error' => 'not found', 'id' => params[:id] }.to_json
  end
end

delete '/documents/:id' do

  if doc = DOCS.delete(params[:id])

    content_type 'application/json'

    { 'deleted' => params[:id] }.to_json
  else

    halt 404, { 'error' => 'not found', 'id' => params[:id] }.to_json
  end
end

delete '/documents' do

  DOCS.clear

  'ok'
end


#
# PREFIX
#

get '/a/b/c' do

  content_type 'text/plain'
  response['Etag'] = '"123456123456"'
  'C'
end

get '/c' do

  content_type 'text/plain'
  'c'
end

put '/a/b/c' do

  response.status = 201
  'put'
end

post '/a/b/c' do

  response.status = 201
  'post'
end

delete '/a/b/c' do

  'delete'
end

#
# TIMEOUT testing

get '/later' do

  sleep 7
  'later'
end


#
# BASIC AUTH

helpers do

  def basic_auth_required

    return if authorized?

    response['WWW-Authenticate'] = 'Basic realm="rufus-jig test"'
    throw :halt, [ 401, "Not authorized\n" ]
  end

  def authorized?

    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials == [ 'admin', 'nimda' ]
  end
end

get '/protected' do

  basic_auth_required

  content_type 'application/json'
  '{ "info": "secretive" }'
end


#
# AUTH COUCH
#
# simulating a basic authentified couchdb instance

get '/tcouch' do

  basic_auth_required

  content_type 'application/json'
  '{ "id": "nada" }'
end

get '/tcouch/_changes' do

  basic_auth_required

  content_type 'application/json'
  '{ "id": "x", "deleted": false, "doc": { "hello": "world" }' + "\r\n"
end


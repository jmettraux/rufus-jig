# encoding: utf-8

# a test sinata server

require 'rubygems'
require 'sinatra'
require 'json'


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

  doc = env['rack.input'].read

  DOCS[params[:id]] = [ request.content_type, doc ]

  response.status = 201

  if params[:mirror] || params[:etag]
    response['Etag'] = "\"#{params[:id]}\"" if params[:etag]
    content_type request.content_type
    doc
  else
    'created.'
  end
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


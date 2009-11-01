# encoding: utf-8

# a test sinata server

require 'rubygems'
require 'sinatra'
require 'json'

#
# basic

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

#
# /documents

DOCS = {}

#post '/stuff' do
#  p 'env'
#  response.status = 201
#  response['Location'] = '/stuff/that'
#  'created.'
#end

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

  'created.'
end

put '/documents/:id' do

  doc = env['rack.input'].read

  DOCS[params[:id]] = [ request.content_type, doc ]

  response.status = 201

  'created.'
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


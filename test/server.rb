# encoding: utf-8

# a test sinata server

require 'rubygems'
require 'sinatra'

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


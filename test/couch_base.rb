
lib = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$: << lib unless $:.include?(lib)

require 'rubygems'
require 'yajl'

# Our default
transport_library = 'patron'

if ARGV.include?( '--em' )
  require 'openssl'
  transport_library = 'em-http'
elsif ARGV.include?( '--net' )
  transport_library = 'net/http'
end

p [ :lib, transport_library ]

require transport_library

require 'rufus/jig'

require 'test/unit'

if transport_library == 'em-http'
  Thread.new { EM.run {} }
  Thread.pass until EM.reactor_running?
end


begin
  Rufus::Jig::Http.new('127.0.0.1', 5984).get('/_all_dbs')
rescue Exception => e
  p e
  puts
  puts "couch not running..."
  puts
  exit(1)
end


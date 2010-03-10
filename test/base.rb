
lib = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift(lib) unless $:.include?(lib)

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

require transport_library

require 'rufus/jig'

require 'test/unit'

if transport_library == 'em-http'
  Thread.new { EM.run {} }
  Thread.pass until EM.reactor_running?
end

t = nil
begin
  t = Time.now
  Rufus::Jig::Http.new('127.0.0.1', 4567).get('/document', :timeout => -1)
rescue Exception => e
  puts
  p e
  e.backtrace.each { |l| puts l }
  puts
  puts "(#{Time.now - t} seconds)"
  puts
  puts "test server not running, please run :"
  puts
  puts "  ruby test/server.rb"
  puts
  exit(1)
end


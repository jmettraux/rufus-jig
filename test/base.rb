
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

require transport_library

require 'rufus/jig'

require 'test/unit'

if transport_library == 'em-http'
  Thread.new { EM.run {} }
  Thread.pass until EM.reactor_running?
end

#unless $test_server
#
#  pss = `ps aux | grep "test\/server.rb"`
#  puts pss
#
#  $test_server = pss.index(' ruby ') || fork do
#    #exec('ruby test/server.rb')
#    exec('ruby test/server.rb > /dev/null 2>&1')
#  end
#  puts
#  puts "...test server is at #{$test_server}"
#  puts
#  sleep 1
#end

begin
  Rufus::Jig::Http.new('127.0.0.1', 4567).get('/document')
rescue Exception => e
  puts
  p e
  e.backtrace.each { |l| puts l }
  puts
  puts "test server not running, please run :"
  puts
  puts "  ruby test/server.rb"
  puts
  exit(1)
end


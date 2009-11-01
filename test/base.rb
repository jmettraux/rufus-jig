
lib = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$: << lib unless $:.include?(lib)

require 'yajl'
require 'patron'
require 'rufus/jig'

require 'test/unit'

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
rescue
  puts
  puts "test server not running, please run :"
  puts
  puts "  ruby test/server.rb"
  puts
  exit(1)
end



lib = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$: << lib unless $:.include?(lib)

require 'yajl'
require 'patron'
require 'rufus/jig'

require 'test/unit'


begin
  Rufus::Jig::Http.new('127.0.0.1', 5984).get('/_all_dbs')
rescue Exception => e
  p e
  puts
  puts "couch not running..."
  puts
  exit(1)
end


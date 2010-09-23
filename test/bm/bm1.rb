
$:.unshift('lib')
require 'rubygems'
require 'yajl'

# Our default
transport_library = 'net/http'

if ARGV.include?( '--em' )
  require 'openssl'
  transport_library = 'em-http'
elsif ARGV.include?( '--netp' )
  transport_library = 'net/http/persistent'
elsif ARGV.include?( '--patron' )
  transport_library = 'patron'
end

require transport_library

require 'rufus/jig'

#c = Rufus::Jig::Couch.new('127.0.0.1', 5984, 'artsr_development_ruote_msgs')
#p c.get('_all_docs')
#p c.delete("1100!2148379060!2010-06-28!1277767412.550787!002")

require 'benchmark'

N = 10_000

c = Rufus::Jig::Couch.new('127.0.0.1', 5984, 'artsr_development_ruote_msgs')

puts
puts RUBY_VERSION
puts c.http.variant
puts

Benchmark.benchmark(' ' * 31 + Benchmark::Tms::CAPTION, 31) do |b|

  b.report('get') do
    N.times { c.get('_all_docs?include_docs=true') }
  end
end


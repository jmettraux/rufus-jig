

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

unless $advertised
  puts
  puts "http lib is '#{transport_library}' (--net/--netp/--patron/--em)"
  $advertised = true
end

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'yajl'
require 'rufus/jig'


# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
#
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |pa|
  require(pa)
}


RSpec.configure do |config|

  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  config.include CouchHelper
end


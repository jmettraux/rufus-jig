
# Our default
lib = ENV['JIG_LIB'] || 'net/http'

lib = case lib
  when 'net' then 'net/http'
  when 'em' then 'em-http'
  when 'netp' then 'net/http/persisten'
  when 'patron' then 'patron'
  else lib
end

require('openssl') if lib == 'em-http'
require(lib)

unless $advertised
  puts
  puts "JIG_LIB lib is '#{lib}' (net/netp/patron/em)"
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

  config.include ServerHelper
  config.include CouchHelper

  config.before(:all) do
    fork_server
  end
  #config.after(:all) do
  #  kill_server
  #end
    # no need, the child will get killed as the main process (rspec) exits
end


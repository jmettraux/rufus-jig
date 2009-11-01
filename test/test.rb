
#
# testing rufus-jig
#
# Sat Oct 31 22:44:08 JST 2009
#

def load_tests (prefix)

  dp = File.dirname(__FILE__)

  Dir.new(dp).entries.select { |e|
    e.match(/^#{prefix}\_.*\.rb$/)
  }.sort.each { |e|
    load("#{dp}/#{e}")
  }
end

load_tests('ut')
load_tests('ct') if ARGV.include?('--couch')


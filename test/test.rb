
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

set = if ARGV.include?('--all')
  %w[ ut ct ]
elsif ARGV.include?('--couch')
  %w[ ct ]
else
  %w[ ut cut ]
end

set.each { |prefix| load_tests(prefix) }


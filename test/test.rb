
#
# testing rufus-jig
#
# Sat Oct 31 22:44:08 JST 2009
#

dp = File.dirname(__FILE__)

Dir.new(dp).entries.select { |e|
  e.match(/^ut\_.*\.rb$/)
}.sort.each { |e|
  load("#{dp}/#{e}")
}


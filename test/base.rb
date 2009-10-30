
lib = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$: << lib unless $:.include?(lib)

require 'patron'
require 'rufus/couch'

require 'test/unit'


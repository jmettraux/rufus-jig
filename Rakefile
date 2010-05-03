

require 'lib/rufus/jig/version.rb'

require 'rubygems'
require 'rake'


#
# CLEAN

require 'rake/clean'
CLEAN.include('pkg', 'tmp', 'html')
task :default => [ :clean ]


#
# GEM

require 'jeweler'

Jeweler::Tasks.new do |gem|

  gem.version = Rufus::Jig::VERSION
  gem.name = 'rufus-jig'
  gem.summary = 'An HTTP client, greedy with JSON content, GETting conditionally.'

  gem.description = %{
    Json Interwebs Get.

    An HTTP client, greedy with JSON content, GETting conditionally.

    Uses Patron and Yajl-ruby whenever possible.
  }
  gem.email = 'jmettraux@gmail.com'
  gem.homepage = 'http://github.com/jmettraux/rufus-jig/'
  gem.authors = [ 'John Mettraux', 'Kenneth Kalmer' ]
  gem.rubyforge_project = 'rufus'

  gem.test_file = 'test/test.rb'

  gem.add_dependency 'rufus-lru'
  gem.add_dependency 'rufus-json', '>= 0.2.1'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'yard'
  gem.add_development_dependency 'jeweler'
  gem.add_development_dependency 'patron'
  gem.add_development_dependency 'em-http-request'

  # gemspec spec : http://www.rubygems.org/read/chapter/20
end
Jeweler::GemcutterTasks.new


#
# DOC

begin

  require 'yard'

  YARD::Rake::YardocTask.new do |doc|
    doc.options = [
      '-o', 'html/rufus-jig', '--title',
      "rufus-jig #{Rufus::Jig::VERSION}"
    ]
  end

rescue LoadError

  task :yard do
    abort "YARD is not available : sudo gem install yard"
  end
end


#
# TO THE WEB

task :upload_website => [ :clean, :yard ] do

  account = 'jmettraux@rubyforge.org'
  webdir = '/var/www/gforge-projects/rufus'

  sh "rsync -azv -e ssh html/rufus-jig #{account}:#{webdir}/"
end


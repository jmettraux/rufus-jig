
require 'lib/rufus/jig/version.rb'

require 'rubygems'
require 'rake'


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

    Uses Yajl-ruby whenever possible.
  }
  gem.email = 'jmettraux@gmail.com'
  gem.homepage = 'http://github.com/jmettraux/rufus-jig/'
  gem.authors = [ 'John Mettraux', 'Kenneth Kalmer' ]
  gem.rubyforge_project = 'rufus'

  gem.add_dependency 'rufus-lru'
  gem.add_dependency 'rufus-json', '>= 0.2.5'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', '~> 2.2.0'
  gem.add_development_dependency 'yard'
  gem.add_development_dependency 'jeweler'
  gem.add_development_dependency 'patron'
  gem.add_development_dependency 'em-http-request'
  gem.add_development_dependency 'net-http-persistent', '>= 1.4'

  # gemspec spec : http://www.rubygems.org/read/chapter/20
end
Jeweler::GemcutterTasks.new


#
# CLEAN

require 'rake/clean'
CLEAN.include('pkg', 'tmp', 'html', 'rdoc', 'server.log')

#
# SPEC / TEST

#task :spec => :check_dependencies do
task :spec do
  sh 'rspec spec/'
end
task :test => :spec

task :default => :spec

desc %{
  runs the specs against net, netp, patron and em
}
task :specs do
  puts; puts "-" * 80; puts
  sh 'export JIG_LIB=net; rspec -f p spec/; exit 0'
  puts; puts "-" * 80; puts
  sh 'export JIG_LIB=netp; rspec -f p spec/; exit 0'
  puts; puts "-" * 80; puts
  sh 'export JIG_LIB=patron; rspec -f p spec/; exit 0'
  puts; puts "-" * 80; puts
  sh 'export JIG_LIB=em; rspec -f p spec/; exit 0'
  puts; puts "-" * 80; puts
end


#
# DOC

#
# make sure to have rdoc 2.5.x to run that
#
require 'rake/rdoctask'
Rake::RDocTask.new do |rd|
  rd.main = 'README.rdoc'
  rd.rdoc_dir = 'rdoc/rufus-jig'
  rd.rdoc_files.include('README.rdoc', 'CHANGELOG.txt', 'lib/**/*.rb')
  rd.title = "rufus-jig #{Rufus::Jig::VERSION}"
end


#
# TO THE WEB

task :upload_rdoc => [ :clean, :rdoc ] do

  account = 'jmettraux@rubyforge.org'
  webdir = '/var/www/gforge-projects/rufus'

  sh "rsync -azv -e ssh rdoc/rufus-jig #{account}:#{webdir}/"
end


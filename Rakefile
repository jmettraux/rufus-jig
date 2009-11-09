
require 'rubygems'

require 'rake'
require 'rake/clean'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/testtask'
#require 'tasks/dev'

#begin
#  require 'hanna/rdoctask'
#rescue LoadError => e
#  require 'rake/rdoctask'
#end

gemspec = File.read('rufus-jig.gemspec')
eval "gemspec = #{gemspec}"

#
# tasks

CLEAN.include('pkg', 'tmp', 'html')

task :default => [ :clean, :repackage ]


#
# TESTING

task :test do
  puts
  puts "please run one of those :"
  puts
  puts "  ruby test/test.rb"
  puts "  ruby test/test.rb --all"
  puts "  ruby test/test.rb --couch"
  puts
end


#
# VERSION

task :change_version do

  version = ARGV.pop
  `sedip "s/VERSION = '.*'/VERSION = '#{version}'/" lib/rufus/jig.rb`
  `sedip "s/s.version = '.*'/s.version = '#{version}'/" rufus-jig.gemspec`
  exit 0 # prevent rake from triggering other tasks
end


#
# PACKAGING

Rake::GemPackageTask.new(gemspec) do |pkg|
  #pkg.need_tar = true
end

Rake::PackageTask.new('rufus-jig', gemspec.version) do |pkg|

  pkg.need_zip = true

  pkg.package_files = FileList[
    'Rakefile',
    '*.txt',
    'lib/**/*',
    'test/**/*'
  ].to_a
  #pkg.package_files.delete('lib/tokyotyrant.rb')

  class << pkg
    def package_name
      "#{@name}-#{@version}-src"
    end
  end
end


#
# DOCUMENTATION

task :rdoc do
  sh %{
    rm -fR html/rufus-jig
    yardoc 'lib/**/*.rb' \
      -o html/rufus-jig \
      --title 'rufus-jig'
  }
end


#
# WEBSITE

task :upload_website => [ :clean, :rdoc ] do

  account = 'jmettraux@rubyforge.org'
  webdir = '/var/www/gforge-projects/rufus'

  sh "rsync -azv -e ssh html/rufus-jig #{account}:#{webdir}/"
end


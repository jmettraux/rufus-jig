
Gem::Specification.new do |s|

  s.name = 'rufus-jig'

  s.version = File.read(
    File.expand_path('../lib/rufus/jig/version.rb', __FILE__)
  ).match(/ VERSION *= *['"]([^'"]+)/)[1]

  s.platform = Gem::Platform::RUBY
  s.authors = [ 'John Mettraux', 'Kenneth Kalmer' ]
  s.email = %w[ jmettraux@gmail.com kenneth@clearplanet.co.za  ]
  s.homepage = 'http://github.com/jmettraux/rufus-jig/'
  s.rubyforge_project = 'rufus'
  s.summary = 'An HTTP client, greedy with JSON content, GETting conditionally.'
  s.description = %{
Json Interwebs Get.

An HTTP client, greedy with JSON content, GETting conditionally.

Uses Yajl-ruby whenever possible.
  }

  #s.files = `git ls-files`.split("\n")
  s.files = Dir[
    'Rakefile',
    'lib/**/*.rb', 'spec/**/*.rb', 'test/**/*.rb',
    '*.gemspec', '*.txt', '*.rdoc', '*.md', '*.mdown'
  ]

  s.add_dependency 'rufus-lru'
  s.add_dependency 'rufus-json', '>= 1.0.1'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 2.6.0'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'jeweler'
  s.add_development_dependency 'patron'
  s.add_development_dependency 'em-http-request'
  s.add_development_dependency 'net-http-persistent', '>= 1.4'

  s.require_path = 'lib'
end


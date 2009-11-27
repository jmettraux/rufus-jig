
Gem::Specification.new do |s|

  s.name = 'rufus-jig'
  s.version = '0.1.1'
  s.authors = [ 'John Mettraux', 'Kenneth Kalmer' ]
  s.email = 'jmettraux@gmail.com'
  s.homepage = 'http://github.com/jmettraux/rufus-jig'
  s.platform = Gem::Platform::RUBY
  s.summary = 'An HTTP client, greedy with JSON content, GETting conditionally.'

  s.description = %{
    Json Internet Get.

    An HTTP client, greedy with JSON content, GETting conditionally.

    Uses Patron and Yajl-ruby whenever possible.
  }

  s.require_path = 'lib'
  s.test_file = 'test/test.rb'
  s.has_rdoc = true
  s.extra_rdoc_files = %w{ README.rdoc CHANGELOG.txt CREDITS.txt LICENSE.txt }
  s.rubyforge_project = 'rufus'

  #%w[ patron yajl-ruby ].each do |d|
  #  s.requirements << d
  #  s.add_dependency(d)
  #end

  #s.files = Dir['lib/**/*.rb'] + Dir['*.txt'] - [ 'lib/tokyotyrant.rb' ]
  s.files = Dir['lib/**/*.rb'] + Dir['*.txt'] + Dir['*.rdoc']
end


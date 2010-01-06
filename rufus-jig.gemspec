# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rufus-jig}
  s.version = "0.1.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Mettraux", "Kenneth Kalmer"]
  s.date = %q{2010-01-06}
  s.description = %q{
    Json Interwebs Get.

    An HTTP client, greedy with JSON content, GETting conditionally.

    Uses Patron and Yajl-ruby whenever possible.
  }
  s.email = %q{jmettraux@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE.txt",
     "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     "CHANGELOG.txt",
     "CREDITS.txt",
     "LICENSE.txt",
     "README.rdoc",
     "Rakefile",
     "TODO.txt",
     "lib/rufus-jig.rb",
     "lib/rufus/jig.rb",
     "lib/rufus/jig/couch.rb",
     "lib/rufus/jig/http.rb",
     "lib/rufus/jig/path.rb",
     "lib/rufus/jig/version.rb",
     "rufus-jig.gemspec",
     "test/base.rb",
     "test/conc/put_vs_delete.rb",
     "test/couch_base.rb",
     "test/ct_0_couch.rb",
     "test/ct_1_couchdb.rb",
     "test/ct_2_couchdb_options.rb",
     "test/server.rb",
     "test/test.rb",
     "test/ut_0_http_get.rb",
     "test/ut_1_http_post.rb",
     "test/ut_2_http_delete.rb",
     "test/ut_3_http_put.rb",
     "test/ut_4_http_prefix.rb",
     "test/ut_5_http_misc.rb",
     "test/ut_6_args.rb"
  ]
  s.homepage = %q{http://github.com/jmettraux/rufus-jig/}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rufus}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{An HTTP client, greedy with JSON content, GETting conditionally.}
  s.test_files = [
    "test/test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rufus-lru>, [">= 0"])
      s.add_runtime_dependency(%q<rufus-json>, [">= 0"])
      s.add_development_dependency(%q<yard>, [">= 0"])
    else
      s.add_dependency(%q<rufus-lru>, [">= 0"])
      s.add_dependency(%q<rufus-json>, [">= 0"])
      s.add_dependency(%q<yard>, [">= 0"])
    end
  else
    s.add_dependency(%q<rufus-lru>, [">= 0"])
    s.add_dependency(%q<rufus-json>, [">= 0"])
    s.add_dependency(%q<yard>, [">= 0"])
  end
end


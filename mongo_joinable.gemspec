# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mongo_joinable/version"

Gem::Specification.new do |s|
  s.name        = "mongo_joinable"
  s.version     = MongoJoinable::VERSION
  s.authors     = ["hello hello"]
  s.email       = ["blah@gmail.com"]
  s.homepage    = "https://github.com/bluswtr"
  s.summary     = %q{ adds joining feature to mongoid/mongo_mapper }
  s.description = %q{ Mongo Joinable adds joining feature to mongoid/mongo_mapper }

  # s.rubyforge_project = "mongo_joinable"

  # s.add_development_dependency('rspec', '> 2.7.0')
  # s.add_development_dependency('mongoid', '> 2.4.0')
  # s.add_development_dependency('mongo_mapper', '> 0.10.0')
  # s.add_development_dependency('bson_ext', '> 1.5.0')
  # s.add_development_dependency('database_cleaner', '>0.7.0')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

end

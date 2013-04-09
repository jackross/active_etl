# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "active_etl/version"

Gem::Specification.new do |s|
  s.name        = "active_etl"
  s.version     = ActiveETL::VERSION
  s.authors     = ["Jack A Ross"]
  s.email       = ["jack.ross@technekes.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "active_etl"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "activerecord", "~> 3.2.0.rc2"
  s.add_runtime_dependency "resque"
end

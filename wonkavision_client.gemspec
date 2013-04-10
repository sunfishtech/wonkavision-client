# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "wonkavision_client/version"

Gem::Specification.new do |s|
  s.name        = "wonkavision_client"
  s.version     = Wonkavision::Client::VERSION
  s.authors     = ["Nathan Stults"]
  s.email       = ["nathan@sunfish.io"]
  s.homepage    = ""
  s.summary     = %q{A client. for wonkavision. BAM!}
  s.description = %q{Someday you will understand. Someday, somebody will understand.}

  s.rubyforge_project = "wonkavision-client"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "faraday", "~> 0.8.7"
  s.add_dependency "yajl-ruby"
  s.add_dependency "certified"

  s.add_development_dependency "rspec", "~> 2.6.0"
end

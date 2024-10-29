# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "enumerable-lazy"
  s.version     = "0.0.2"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Yutaka HARA"]
  s.email       = ["yutaka.hara.gmail.com"]
  s.homepage    = "https://github.com/yhara/enumerable-lazy"
  s.summary     = %q{**deprecated**}
  s.description = s.summary
  s.license = "MIT"

  s.files         = `git ls-files`.split("\n")
  #s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  #s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

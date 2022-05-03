# -*- encoding: utf-8 -*-
require File.expand_path('../lib/guard/shotgun/version', __FILE__)
require 'date'

Gem::Specification.new do |gem|
  gem.name          = "guard-shotgun"
  gem.version       = Guard::ShotgunVersion::VERSION
  gem.authors       = ["romain@softr.li", "Colin Rymer"]
  gem.email         = ["romain@softr.li", "colin.rymer@gmail.com"]
  gem.description   = 'This gem provides a Guard that restarts Rack apps when watched files are modified similar. Similar to the wonderful Shotgun by rtomayko'
  gem.summary       = 'Shotgun-like Guard for Rack apps'
  gem.date          = Date.today.to_s
  gem.homepage      = "http://github.com/rchampourlier/guard-shotgun"
  gem.license       = 'MIT'
  gem.executables   = []
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- spec/*`.split("\n")
  gem.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  gem.require_paths = ["lib"]
  gem.required_ruby_version = '>= 1.9'

  gem.add_dependency 'guard', '~> 2.0'
  gem.add_dependency 'ffi'
  gem.add_dependency 'spoon'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
end


# -*- encoding: utf-8 -*-
# stub: virtus_convert 0.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "virtus_convert".freeze
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Benjamin Guest".freeze]
  s.bindir = "exe".freeze
  s.date = "2015-07-15"
  s.description = "Convert deeply nested Virtus or other objects that respond to attributes to hashes and arrays".freeze
  s.email = ["benguest@gmail.com".freeze]
  s.homepage = "https://github.com/bguest/virtus_convert".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Converts nested object trees to hashes / arrays".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, ["~> 1.8"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_development_dependency(%q<pry-byebug>.freeze, ["~> 3.0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.2"])
    s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.9.2"])
    s.add_development_dependency(%q<dotenv>.freeze, ["~> 2.0"])
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.8"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<pry-byebug>.freeze, ["~> 3.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.2"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.9.2"])
    s.add_dependency(%q<dotenv>.freeze, ["~> 2.0"])
  end
end

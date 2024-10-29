# -*- encoding: utf-8 -*-
# stub: dry-logic 0.1.4 ruby lib

Gem::Specification.new do |s|
  s.name = "dry-logic".freeze
  s.version = "0.1.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Piotr Solnica".freeze]
  s.date = "2016-01-27"
  s.email = ["piotr.solnica@gmail.com".freeze]
  s.homepage = "https://github.com/dryrb/dry-logic".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Predicate logic with rule composition".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<dry-container>.freeze, ["~> 0.2", ">= 0.2.6"])
    s.add_runtime_dependency(%q<dry-equalizer>.freeze, ["~> 0.2"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  else
    s.add_dependency(%q<dry-container>.freeze, ["~> 0.2", ">= 0.2.6"])
    s.add_dependency(%q<dry-equalizer>.freeze, ["~> 0.2"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
  end
end

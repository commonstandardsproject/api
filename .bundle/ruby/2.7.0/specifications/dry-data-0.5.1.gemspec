# -*- encoding: utf-8 -*-
# stub: dry-data 0.5.1 ruby lib

Gem::Specification.new do |s|
  s.name = "dry-data".freeze
  s.version = "0.5.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Piotr Solnica".freeze]
  s.bindir = "exe".freeze
  s.date = "2016-01-11"
  s.description = "Simple type-system for Ruby".freeze
  s.email = ["piotr.solnica@gmail.com".freeze]
  s.homepage = "https://github.com/dryrb/dry-data".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Simple type-system for Ruby".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<thread_safe>.freeze, ["~> 0.3"])
    s.add_runtime_dependency(%q<dry-container>.freeze, ["~> 0.2"])
    s.add_runtime_dependency(%q<dry-equalizer>.freeze, ["~> 0.2"])
    s.add_runtime_dependency(%q<dry-configurable>.freeze, ["~> 0.1"])
    s.add_runtime_dependency(%q<dry-logic>.freeze, ["~> 0.1"])
    s.add_runtime_dependency(%q<inflecto>.freeze, ["~> 0.0.0", ">= 0.0.2"])
    s.add_runtime_dependency(%q<kleisli>.freeze, ["~> 0.2"])
    s.add_development_dependency(%q<bundler>.freeze, ["~> 1.7"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.3"])
  else
    s.add_dependency(%q<thread_safe>.freeze, ["~> 0.3"])
    s.add_dependency(%q<dry-container>.freeze, ["~> 0.2"])
    s.add_dependency(%q<dry-equalizer>.freeze, ["~> 0.2"])
    s.add_dependency(%q<dry-configurable>.freeze, ["~> 0.1"])
    s.add_dependency(%q<dry-logic>.freeze, ["~> 0.1"])
    s.add_dependency(%q<inflecto>.freeze, ["~> 0.0.0", ">= 0.0.2"])
    s.add_dependency(%q<kleisli>.freeze, ["~> 0.2"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.7"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.3"])
  end
end

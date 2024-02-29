# -*- encoding: utf-8 -*-
# stub: asana 0.10.3 ruby lib

Gem::Specification.new do |s|
  s.name = "asana".freeze
  s.version = "0.10.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Txus".freeze]
  s.bindir = "exe".freeze
  s.date = "2021-01-07"
  s.description = "Official Ruby client for the Asana API".freeze
  s.email = ["me@txus.io".freeze]
  s.homepage = "https://github.com/asana/ruby-asana".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new("> 2.0".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Official Ruby client for the Asana API".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<oauth2>.freeze, ["~> 1.4"])
    s.add_runtime_dependency(%q<faraday>.freeze, ["~> 1.0"])
    s.add_runtime_dependency(%q<faraday_middleware>.freeze, ["~> 1.0"])
    s.add_runtime_dependency(%q<faraday_middleware-multi_json>.freeze, ["~> 0.0"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.2"])
    s.add_development_dependency(%q<appraisal>.freeze, [">= 2.1", "~> 2.1"])
  else
    s.add_dependency(%q<oauth2>.freeze, ["~> 1.4"])
    s.add_dependency(%q<faraday>.freeze, ["~> 1.0"])
    s.add_dependency(%q<faraday_middleware>.freeze, ["~> 1.0"])
    s.add_dependency(%q<faraday_middleware-multi_json>.freeze, ["~> 0.0"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.2"])
    s.add_dependency(%q<appraisal>.freeze, [">= 2.1", "~> 2.1"])
  end
end

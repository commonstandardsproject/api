# -*- encoding: utf-8 -*-
# stub: shotgun 0.9.2 ruby lib

Gem::Specification.new do |s|
  s.name = "shotgun".freeze
  s.version = "0.9.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ryan Tomayko".freeze]
  s.date = "2016-09-10"
  s.description = "Reloading Rack development server".freeze
  s.email = "rtomayko@gmail.com".freeze
  s.executables = ["shotgun".freeze]
  s.files = ["bin/shotgun".freeze]
  s.homepage = "https://github.com/rtomayko/shotgun".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Reloading Rack development server".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rack>.freeze, [">= 1.0"])
  else
    s.add_dependency(%q<rack>.freeze, [">= 1.0"])
  end
end

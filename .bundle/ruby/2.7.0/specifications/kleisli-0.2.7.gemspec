# -*- encoding: utf-8 -*-
# stub: kleisli 0.2.7 ruby lib

Gem::Specification.new do |s|
  s.name = "kleisli".freeze
  s.version = "0.2.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Josep M. Bach".freeze, "Ryan Levick".freeze]
  s.date = "2015-12-17"
  s.description = "Usable, idiomatic common monads in Ruby".freeze
  s.email = ["josep.m.bach@gmail.com".freeze, "ryan.levick@gmail.com".freeze]
  s.homepage = "https://github.com/txus/kleisli".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Usable, idiomatic common monads in Ruby".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, ["~> 1.6"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 5.5"])
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.6"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.5"])
  end
end

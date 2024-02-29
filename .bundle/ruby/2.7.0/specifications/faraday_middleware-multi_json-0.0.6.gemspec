# -*- encoding: utf-8 -*-
# stub: faraday_middleware-multi_json 0.0.6 ruby lib

Gem::Specification.new do |s|
  s.name = "faraday_middleware-multi_json".freeze
  s.version = "0.0.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Dennis Rogenius".freeze]
  s.date = "2014-05-13"
  s.description = "Faraday response parser using MultiJson".freeze
  s.email = ["denro03@gmail.com".freeze]
  s.homepage = "https://www.github.com/denro/faraday_middleware-multi_json".freeze
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Response JSON parser using MultiJson and FaradayMiddleware".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<faraday_middleware>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<multi_json>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  else
    s.add_dependency(%q<faraday_middleware>.freeze, [">= 0"])
    s.add_dependency(%q<multi_json>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
  end
end

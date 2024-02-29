# -*- encoding: utf-8 -*-
# stub: grape 0.16.2 ruby lib

Gem::Specification.new do |s|
  s.name = "grape".freeze
  s.version = "0.16.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Bleigh".freeze]
  s.date = "2016-04-11"
  s.description = "A Ruby framework for rapid API development with great conventions.".freeze
  s.email = ["michael@intridea.com".freeze]
  s.homepage = "https://github.com/ruby-grape/grape".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "A simple Ruby framework for building REST-like APIs.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rack>.freeze, [">= 1.3.0"])
    s.add_runtime_dependency(%q<mustermann19>.freeze, ["~> 0.4.3"])
    s.add_runtime_dependency(%q<rack-accept>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<activesupport>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<multi_json>.freeze, [">= 1.3.2"])
    s.add_runtime_dependency(%q<multi_xml>.freeze, [">= 0.5.2"])
    s.add_runtime_dependency(%q<hashie>.freeze, [">= 2.1.0"])
    s.add_runtime_dependency(%q<virtus>.freeze, [">= 1.0.0"])
    s.add_runtime_dependency(%q<builder>.freeze, [">= 0"])
    s.add_development_dependency(%q<grape-entity>.freeze, ["= 0.5.0"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 10"])
    s.add_development_dependency(%q<maruku>.freeze, [">= 0"])
    s.add_development_dependency(%q<yard>.freeze, [">= 0"])
    s.add_development_dependency(%q<rack-test>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<cookiejar>.freeze, [">= 0"])
    s.add_development_dependency(%q<rack-contrib>.freeze, [">= 0"])
    s.add_development_dependency(%q<mime-types>.freeze, ["< 3.0"])
    s.add_development_dependency(%q<appraisal>.freeze, [">= 0"])
    s.add_development_dependency(%q<benchmark-ips>.freeze, [">= 0"])
    s.add_development_dependency(%q<rubocop>.freeze, ["= 0.35.1"])
  else
    s.add_dependency(%q<rack>.freeze, [">= 1.3.0"])
    s.add_dependency(%q<mustermann19>.freeze, ["~> 0.4.3"])
    s.add_dependency(%q<rack-accept>.freeze, [">= 0"])
    s.add_dependency(%q<activesupport>.freeze, [">= 0"])
    s.add_dependency(%q<multi_json>.freeze, [">= 1.3.2"])
    s.add_dependency(%q<multi_xml>.freeze, [">= 0.5.2"])
    s.add_dependency(%q<hashie>.freeze, [">= 2.1.0"])
    s.add_dependency(%q<virtus>.freeze, [">= 1.0.0"])
    s.add_dependency(%q<builder>.freeze, [">= 0"])
    s.add_dependency(%q<grape-entity>.freeze, ["= 0.5.0"])
    s.add_dependency(%q<rake>.freeze, ["~> 10"])
    s.add_dependency(%q<maruku>.freeze, [">= 0"])
    s.add_dependency(%q<yard>.freeze, [">= 0"])
    s.add_dependency(%q<rack-test>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<cookiejar>.freeze, [">= 0"])
    s.add_dependency(%q<rack-contrib>.freeze, [">= 0"])
    s.add_dependency(%q<mime-types>.freeze, ["< 3.0"])
    s.add_dependency(%q<appraisal>.freeze, [">= 0"])
    s.add_dependency(%q<benchmark-ips>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop>.freeze, ["= 0.35.1"])
  end
end

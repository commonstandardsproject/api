# -*- encoding: utf-8 -*-
# stub: slack-notify 0.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "slack-notify".freeze
  s.version = "0.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Dan Sosedoff".freeze]
  s.date = "2020-12-23"
  s.description = "Send notifications to a Slack channel".freeze
  s.email = ["dan.sosedoff@gmail.com".freeze]
  s.homepage = "https://github.com/sosedoff/slack-notify".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Send notifications to a Slack channel".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, [">= 1.3"])
    s.add_development_dependency(%q<rake>.freeze, [">= 10"])
    s.add_development_dependency(%q<simplecov>.freeze, [">= 0.7"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 2.13"])
    s.add_development_dependency(%q<webmock>.freeze, [">= 1.0"])
    s.add_runtime_dependency(%q<faraday>.freeze, [">= 0.9"])
    s.add_runtime_dependency(%q<json>.freeze, [">= 1.8"])
  else
    s.add_dependency(%q<bundler>.freeze, [">= 1.3"])
    s.add_dependency(%q<rake>.freeze, [">= 10"])
    s.add_dependency(%q<simplecov>.freeze, [">= 0.7"])
    s.add_dependency(%q<rspec>.freeze, [">= 2.13"])
    s.add_dependency(%q<webmock>.freeze, [">= 1.0"])
    s.add_dependency(%q<faraday>.freeze, [">= 0.9"])
    s.add_dependency(%q<json>.freeze, [">= 1.8"])
  end
end

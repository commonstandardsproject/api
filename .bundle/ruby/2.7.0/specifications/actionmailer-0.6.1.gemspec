# -*- encoding: utf-8 -*-
# stub: actionmailer 0.6.1 ruby lib

Gem::Specification.new do |s|
  s.name = "actionmailer".freeze
  s.version = "0.6.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Heinemeier Hansson".freeze]
  s.autorequire = "action_mailer".freeze
  s.date = "2005-01-18"
  s.description = "Makes it trivial to test and deliver emails sent from a single service layer.".freeze
  s.email = "david@loudthinking.com".freeze
  s.homepage = "http://actionmailer.rubyonrails.org".freeze
  s.required_ruby_version = Gem::Requirement.new("> 0.0.0".freeze)
  s.requirements = ["none".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Service layer for easy email delivery and testing.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 1
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<actionpack>.freeze, [">= 0.9.5"])
  else
    s.add_dependency(%q<actionpack>.freeze, [">= 0.9.5"])
  end
end

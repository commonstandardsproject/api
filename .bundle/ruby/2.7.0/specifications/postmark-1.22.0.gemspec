# -*- encoding: utf-8 -*-
# stub: postmark 1.22.0 ruby lib

Gem::Specification.new do |s|
  s.name = "postmark".freeze
  s.version = "1.22.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.7".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tomek Maszkowski".freeze, "Igor Balos".freeze, "Artem Chistyakov".freeze, "Nick Hammond".freeze, "Petyo Ivanov".freeze, "Ilya Sabanin".freeze]
  s.date = "2021-08-25"
  s.description = "Use this gem to send emails through Postmark HTTP API and retrieve info about bounces.".freeze
  s.email = "tomek@wildbit.com".freeze
  s.extra_rdoc_files = ["LICENSE".freeze, "README.md".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze]
  s.homepage = "http://postmarkapp.com".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "\n    ==================\n    Thanks for installing the postmark gem. If you don't have an account, please\n    sign up at http://postmarkapp.com/.\n\n    Review the README.md for implementation details and examples.\n    ==================\n  ".freeze
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Official Postmark API wrapper.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<json>.freeze, [">= 0"])
    s.add_development_dependency(%q<mail>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  else
    s.add_dependency(%q<json>.freeze, [">= 0"])
    s.add_dependency(%q<mail>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end

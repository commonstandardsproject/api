# -*- encoding: utf-8 -*-
# stub: algoliasearch 1.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "algoliasearch".freeze
  s.version = "1.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Algolia".freeze]
  s.date = "2016-01-09"
  s.description = "A simple Ruby client for the algolia.com REST API".freeze
  s.email = "contact@algolia.com".freeze
  s.extra_rdoc_files = ["ChangeLog".freeze, "LICENSE.txt".freeze, "README.md".freeze]
  s.files = ["ChangeLog".freeze, "LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "http://github.com/algolia/algoliasearch-client-ruby".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "A simple Ruby client for the algolia.com REST API".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<httpclient>.freeze, ["~> 2.4"])
    s.add_runtime_dependency(%q<json>.freeze, [">= 1.5.1"])
    s.add_development_dependency(%q<travis>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<rdoc>.freeze, [">= 0"])
  else
    s.add_dependency(%q<httpclient>.freeze, ["~> 2.4"])
    s.add_dependency(%q<json>.freeze, [">= 1.5.1"])
    s.add_dependency(%q<travis>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rdoc>.freeze, [">= 0"])
  end
end

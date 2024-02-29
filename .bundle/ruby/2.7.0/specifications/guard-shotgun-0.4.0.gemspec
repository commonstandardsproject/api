# -*- encoding: utf-8 -*-
# stub: guard-shotgun 0.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "guard-shotgun".freeze
  s.version = "0.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["romain@softr.li".freeze, "Colin Rymer".freeze]
  s.date = "2014-09-16"
  s.description = "This gem provides a Guard that restarts Rack apps when watched files are modified similar. Similar to the wonderful Shotgun by rtomayko".freeze
  s.email = ["romain@softr.li".freeze, "colin.rymer@gmail.com".freeze]
  s.extra_rdoc_files = ["LICENSE".freeze, "README.md".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze]
  s.homepage = "http://github.com/rchampourlier/guard-shotgun".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Shotgun-like Guard for Rack apps".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<guard>.freeze, ["~> 2.0"])
    s.add_runtime_dependency(%q<ffi>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<spoon>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  else
    s.add_dependency(%q<guard>.freeze, ["~> 2.0"])
    s.add_dependency(%q<ffi>.freeze, [">= 0"])
    s.add_dependency(%q<spoon>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
  end
end

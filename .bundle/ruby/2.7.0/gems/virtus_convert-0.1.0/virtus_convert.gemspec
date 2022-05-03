# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'virtus_convert/version'

Gem::Specification.new do |spec|
  spec.name          = "virtus_convert"
  spec.version       = VirtusConvert::VERSION
  spec.authors       = ["Benjamin Guest"]
  spec.email         = ["benguest@gmail.com"]

  spec.summary       = %q{Converts nested object trees to hashes / arrays}
  spec.description   = %q{Convert deeply nested Virtus or other objects that respond to attributes to hashes and arrays}
  spec.homepage      = "https://github.com/bguest/virtus_convert"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'pry-byebug', '~>3.0'
  spec.add_development_dependency 'rspec', '~>3.2'
  spec.add_development_dependency 'simplecov', '~>0.9.2'
  spec.add_development_dependency 'dotenv', '~>2.0'
end

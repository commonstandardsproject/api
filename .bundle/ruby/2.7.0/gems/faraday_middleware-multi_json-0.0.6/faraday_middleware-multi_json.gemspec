# -*- encoding: utf-8 -*-
#
Gem::Specification.new do |gem|
  gem.authors       = ['Dennis Rogenius']
  gem.email         = ['denro03@gmail.com']
  gem.description   = %q{Faraday response parser using MultiJson}
  gem.summary       = %q{Response JSON parser using MultiJson and FaradayMiddleware}
  gem.homepage      = 'https://www.github.com/denro/faraday_middleware-multi_json'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'faraday_middleware-multi_json'
  gem.require_paths = ['lib']
  gem.version       = '0.0.6'

  gem.add_dependency 'faraday_middleware'
  gem.add_dependency 'multi_json'

  gem.add_development_dependency 'rspec'
end

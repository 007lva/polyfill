# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'polyfill/version'

Gem::Specification.new do |spec|
  spec.name    = 'polyfill'
  spec.version = Polyfill::VERSION
  spec.authors = ['Aaron Lasseigne']
  spec.email   = ['aaron.lasseigne@gmail.com']

  spec.summary  = 'Adds newer Ruby methods to older versions.'
  spec.homepage = ''
  spec.license  = 'MIT'

  spec.required_ruby_version = '>= 2.1'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency 'rubocop', '~> 0.48.1'
end

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-resource-bundle-copier/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-resource-bundle-copier'
  spec.version       = CocoapodsResourceBundleCopier::VERSION
  spec.authors       = ['Harris Borawski']
  spec.email         = ['harris_borawski@intuit.com']
  spec.description   = %q{A short description of cocoapods-resource-bundle-copier.}
  spec.summary       = %q{A longer description of cocoapods-resource-bundle-copier.}
  spec.homepage      = 'https://github.com/EXAMPLE/cocoapods-resource-bundle-copier'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2'
  spec.add_development_dependency 'rake'
end

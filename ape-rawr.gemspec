# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ape-rawr/version'

Gem::Specification.new do |spec|
  spec.name          = "ape-rawr"
  spec.version       = ApeRawr::VERSION
  spec.authors       = ["Anthony Smith"]
  spec.email         = ["anthony@sticksnleaves.com"]
  spec.description   = %q{API parameter validation and error handling for Rails}
  spec.summary       = %q{Validate params and handle errors in a Rails based API}
  spec.homepage      = "https://github.com/anthonator/ape-rawr"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 3.0"
  spec.add_dependency "hashie", "~> 2.0"
  spec.add_dependency "i18n"
  spec.add_dependency "virtus", "~> 0.5"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative 'lib/pokeman/version'

Gem::Specification.new do |spec|
  spec.name          = "pokeman"
  spec.version       = PokeMan::VERSION
  spec.authors       = ["Xyko"]
  spec.email         = ["francisco@corp.globo.com"]

  spec.summary       = %q{Console for pokemon api access.}
  spec.description   = %q{Console to use, and descrive, all api poke mon access and show IV user calculus.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files = %x(git ls-files).split($/)
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_runtime_dependency 'awesome_print', '~> 1.7', '>= 1.7.0'
  spec.add_runtime_dependency 'colorize', '~> 0.7.7'
  spec.add_runtime_dependency 'prompt', '~> 1.2', '>= 1.2.2'
  spec.add_runtime_dependency 'i18n', '~> 0.7', '>= 0.7.0'
  spec.add_runtime_dependency 'rest-client', '~> 1.8', '>= 1.8.0'
  spec.add_runtime_dependency 'poke-go-api', '~> 0.1', '>= 0.1.7'
  spec.add_runtime_dependency 'tty-prompt'
  spec.add_runtime_dependency 'tty'
  spec.add_runtime_dependency 'capybara', '~> 2.8', '>= 2.8.0'
  spec.add_runtime_dependency 'poltergeist', '~> 1.10', '>= 1.10.0'

  spec.required_ruby_version = '>= 2.3.0'

end

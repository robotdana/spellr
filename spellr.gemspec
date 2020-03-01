# frozen_string_literal: true

lib = ::File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spellr/version'

Gem::Specification.new do |spec|
  spec.name = 'spellr'
  spec.version = Spellr::VERSION
  spec.authors = ['Dana Sherson']
  spec.email = ['robot@dana.sh']

  spec.summary = 'Spell check your source code'
  spec.homepage = 'http://github.com/robotdana/spellr'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 2.4'

  spec.files = Dir.glob('{lib,exe,wordlists}/**/{*,.*}') + %w{
    CHANGELOG.md
    Gemfile
    LICENSE.txt
    README.md
    spellr.gemspec
  }
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'mime-types', '~> 3.3.1'
  spec.add_development_dependency 'nokogiri'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'simplecov', '~> 0.18.5'
  spec.add_development_dependency 'tty_string', '>= 0.2.1'
  spec.add_development_dependency 'webmock', '~> 3.8'

  spec.add_dependency 'fast_ignore', '~> 0.6.0'
  spec.add_dependency 'parallel', '~> 1.0'
end

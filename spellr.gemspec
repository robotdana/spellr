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

  if spec.respond_to?(:metadata)
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = spec.homepage
    spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  end

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
  spec.add_development_dependency 'leftovers', '>= 0.4.0'
  spec.add_development_dependency 'mime-types', '~> 3.3.1'
  spec.add_development_dependency 'nokogiri'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.93.1'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.44.1'
  spec.add_development_dependency 'simplecov', '~> 0.18.5'
  spec.add_development_dependency 'simplecov-console'
  spec.add_development_dependency 'tty_string', '>= 1.1.0'
  spec.add_development_dependency 'webmock', '~> 3.8'

  spec.add_dependency 'damerau-levenshtein'
  spec.add_dependency 'fast_ignore', '>= 0.11.0'
  spec.add_dependency 'jaro_winkler'
  spec.add_dependency 'parallel', '~> 1.0'
end

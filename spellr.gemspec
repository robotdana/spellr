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

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  # TODO: use .dockerignore to exclude files from this list
  spec.files = %w{
    CHANGELOG.md
    Gemfile
    Gemfile.lock
    LICENSE.txt
    README.md
    bin/fetch_wordlist/english
    bin/fetch_wordlist/ruby
    exe/spellr
    lib/.spellr.yml
    lib/spellr.rb
    lib/spellr/check.rb
    lib/spellr/cli.rb
    lib/spellr/column_location.rb
    lib/spellr/config.rb
    lib/spellr/config_loader.rb
    lib/spellr/file.rb
    lib/spellr/file_list.rb
    lib/spellr/interactive.rb
    lib/spellr/language.rb
    lib/spellr/line_location.rb
    lib/spellr/line_tokenizer.rb
    lib/spellr/reporter.rb
    lib/spellr/string_format.rb
    lib/spellr/token.rb
    lib/spellr/tokenizer.rb
    lib/spellr/version.rb
    lib/spellr/wordlist.rb
    lib/spellr/wordlist_reporter.rb
    wordlists/dockerfile.txt
    wordlists/html.txt
    wordlists/javascript.txt
    wordlists/ruby.txt
    wordlists/shell.txt
  }
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-eventually'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'tty_string'
  spec.add_dependency 'fast_ignore'
end

# frozen_string_literal: true

Spellr.configure do |config|
  config.word_minimum_length = 3
  config.subword_minimum_length = 3
  config.subword_maximum_count = 0
  config.run_together_words_maximum_length = 10

  config.exclusions = %w{
    /.git/
    .DS_Store
    Gemfile.lock
    .rspec_status
    *.png
    *.jpg
    *.gif
    *.ico
    .gitkeep
    .keep
  }

  config.add_default_dictionary(:natural) do |dict|
    dict.lazy_download(
      diacritic: :both,
      hacker: true
    )
  end

  config.add_default_dictionary(:common)

  config.add_default_dictionary(:ruby) do |dict|
    dict.extensions = %w{
      rb
      rake
      gemspec
      ru
      erb
      haml
      jbuilder
      builder
    }
    dict.filenames = %w{
      Gemfile
      Rakefile
    }
    dict.hashbangs = %w{
      ruby
    }
  end

  config.add_default_dictionary(:html) do |dict|
    dict.extensions = %w{
      html
      hml
      jsx
      tsx
      js
      ts
      haml
      erb
      rb
      builder
    }
  end

  config.add_default_dictionary(:shell) do |dict|
    dict.extensions = %w{
      sh
    }
    dict.hashbangs = %w{
      bash
      sh
    }
  end
end

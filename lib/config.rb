Spellr.configure do |config|
  config.word_minimum_length = 3
  config.subword_minimum_length = 3
  config.subword_maximum_count = 2

  config.exclusions = %w{
    .git/*
    .DS_Store
    Gemfile.lock
    .rspec_status
    *.png
    *.jpg
    *.gif
    *.ico
    .gitkeep
  }

  config.add_default_dictionary(:natural) do |dict|
    dict.lazy_download(
      max_size: 95,
      spelling: %w{US AU CA GBz GBs},
      diacritic: :both,
      special: :hacker
    )
  end

  config.add_default_dictionary(:common)

  config.add_default_dictionary(:ruby) do |dict|
    dict.only = %w{
      *.rb
      Gemfile
      Rakefile
      *.gemspec
      rake
      .travis.yml
    }
    dict.only_hashbangs = %w{ruby}
  end

  config.add_default_dictionary(:'ruby.stdlib') do |dict|
    dict.only = %w{
      *.rb
      Gemfile
      Rakefile
      *.gemspec
      rake
      .travis.yml
    }
    dict.only_hashbangs = %w{ruby}
  end

  config.add_default_dictionary(:shell) do |dict|
    dict.only = %w{*.sh}
    dict.only_hashbangs = %w{bash sh}
  end
end

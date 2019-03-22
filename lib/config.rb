Spellr.configure do |config|
  def default(name)
    Pathname.new(__FILE__).join('..', '..', 'dictionaries', "#{name}.txt")
  end

  config.exclusions = %w{
    .git/*
    .DS_Store
    Gemfile.lock
    .rspec_status
  }

  config.add_dictionary(default(:natural)) do |dict|
    dict.lazy_download(
      max_size: 50,
      spelling: %w{US AU},
      max_variant: 0,
      diacritic: :both,
      special: :hacker
    )
  end

  config.add_dictionary(default(:common))

  config.add_dictionary(default(:ruby)) do |dict|
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

  config.add_dictionary(default(:shell)) do |dict|
    dict.only = %w{*.sh}
    dict.only_hashbangs = %w{bash sh}
  end
end

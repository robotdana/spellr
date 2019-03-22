Spellr.configure do |config|
  def default(name)
    Pathname.new(__FILE__).join('..', '..', 'dictionaries', "#{name}.txt")
  end

  config.add_dictionary(default('natural')) do |dict|
    dict.lazy_download(
      max_size: 50,
      spelling: %w{US AU},
      max_variant: 0,
      diacritic: :both,
      special: :hacker
    )
  end

  config.add_dictionary(default('common'))
end

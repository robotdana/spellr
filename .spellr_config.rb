# frozen_string_literal: true

Spellr.configure do |config|
  config.add_dictionary('dictionary.txt')
  config.dictionaries[:ruby].filenames += %w{README.md}
end

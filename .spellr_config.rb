# frozen_string_literal: true

Spellr.configure do |config|
  config.add_dictionary('dictionary.txt')
  config.dictionaries[:ruby].only += %w{README.md}
end

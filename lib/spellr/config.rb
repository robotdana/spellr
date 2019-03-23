module Spellr
  class Config
    attr_accessor :dictionaries, :exclusions, :reporter
    attr_accessor :word_minimum_length, :subword_minimum_length, :subword_maximum_count

    def initialize
      @dictionaries = {}
      @exclusions = []
      @reporter = Spellr::Reporter
      @word_minimum_length = 3
      @subword_minimum_length = 3
      @subword_maximum_count = 2
    end

    def minimum_dictionary_entry_length
      [word_minimum_length, subword_minimum_length].min
    end

    def run_together_words?
      subword_maximum_count > 1
    end

    def add_dictionary(filename)
      dictionary = Spellr::Dictionary.new(filename)
      yield dictionary if block_given?
      dictionaries[dictionary.name.to_s.to_sym] = dictionary
    end

    def add_default_dictionary(name, &block)
      filename = Spellr::Dictionary::DEFAULT_DIR.join("#{name}.txt")

      add_dictionary(filename, &block)
    end
  end
end

module Spellr
  class Config
    attr_accessor :dictionaries, :exclusions, :reporter
    attr_accessor :subword_minimum_length, :subword_maximum_count

    def initialize
      @dictionaries = {}
      @exclusions = []
      @reporter = Spellr::Reporter
      @subword_minimum_length = 3
      @subword_maximum_count = 3
    end

    def run_together_words?
      subword_maximum_count > 1
    end

    def add_dictionary(filename)
      dictionary = Dictionary.new(filename)
      yield dictionary if block_given?
      dictionaries[dictionary.name.to_s.to_sym] = dictionary
    end
  end
end

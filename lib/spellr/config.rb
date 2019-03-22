module Spellr
  class Config
    attr_accessor :dictionaries, :exclusions

    def initialize
      @dictionaries = {}
      @exclusions = []
    end

    def add_dictionary(filename)
      dictionary = Dictionary.new(filename)
      yield dictionary if block_given?
      dictionaries[dictionary.name.to_s.to_sym] = dictionary
    end
  end
end

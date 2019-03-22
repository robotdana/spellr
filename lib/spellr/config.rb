module Spellr
  class Config
    attr_reader :dictionaries

    def initialize
      @dictionaries = []
    end

    def add_dictionary(filename)
      dictionary = Dictionary.new(filename)
      yield dictionary if block_given?
      dictionaries << dictionary
    end

    def remove_dictionary(name)
      dictionaries.delete_if do |dict|
        dict.name == name.to_s || dict.file == name.to_s
      end
    end
  end
end

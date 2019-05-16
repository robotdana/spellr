# frozen_string_literal: true

module Spellr
  class WordlistReporter
    attr_reader :words
    def initialize
      @words = []
    end

    def finish(_) # rubocop:disable Naming/UncommunicativeMethodParamName
      puts words.sort.uniq.join("\n")
    end

    def call(token)
      words << token.downcase
    end
  end
end

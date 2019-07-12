# frozen_string_literal: true

require 'set'

module Spellr
  class WordlistReporter
    attr_reader :words

    def initialize
      @words = Set.new
    end

    def finish(_checked)
      puts words.sort.join
    end

    def call(token)
      words << token.normalize
    end
  end
end

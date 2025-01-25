# frozen_string_literal: true

require 'set'
require_relative 'base_reporter'

module Spellr
  class WordlistReporter < Spellr::BaseReporter
    def finish
      puts words.sort.join("\n") unless words.empty?
    end

    def call(token)
      words << token.spellr_normalize
    end

    private

    def words
      @words ||= begin
        output.counts[:words] = Set.new unless output.counts.key?(:words)
        output.counts[:words]
      end
    end
  end
end

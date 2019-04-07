# frozen_string_literal: true

require 'fast_ignore'

module Spellr
  class FileList
    include Enumerable

    def wordlist?(file)
      Spellr.config.wordlists.any? { |w| w.path == file }
    end

    def each
      FastIgnore.new(rules: Spellr.config.ignored).each do |file|
        next if wordlist?(file)

        file = Spellr::File.new(file)
        yield(file)
      end
    end

    def to_a
      enum_for(:each).to_a
    end
  end
end

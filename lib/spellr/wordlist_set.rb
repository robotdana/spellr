# frozen_string_literal: true

module Spellr
  class WordlistSet
    def self.for_file(file)
      languages_for_file = Spellr.config.languages_for(file)
      cache.fetch(languages_for_file) do
        cache[languages_for_file] = new(languages_for_file)
      end
    end

    def self.cache
      @cache ||= {}
    end

    def self.clear_cache
      @wordlist_sets = nil
    end

    def initialize(languages)
      @wordlists = languages.flat_map(&:wordlists)
      @wordlists.sort_by!(&:length)
      @wordlists.reverse!
    end

    def include?(term)
      @wordlists.any? { |w| w.include?(term) }
    end

    # this is the same correction algorithm as ruby's DidYouMean::SpellChecker.correct
    # but with early returns and using gems with c extensions
    Suggestion = Struct.new(:word, :jw, :dl)
    def suggestions_unsorted(input) # rubocop:disable Metrics/MethodLength
      require 'jaro_winkler'
      require 'damerau-levenshtein'

      input = input.spellr_normalize
      threshold = 0.77
      suggestions = []

      @wordlists.each do |wordlist|
        wordlist.words.each do |word|
          jw = JaroWinkler.distance(word, input)
          next unless jw >= threshold

          dl = DamerauLevenshtein.distance(word, input)
          suggestions << Suggestion.new(word, jw, dl)
        end
      end

      suggestions.sort_by!(&:jw)
      suggestions.reverse!
    end

    def suggestions(input) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      input = input.spellr_normalize
      suggestions = suggestions_unsorted(input)
      # correct mistypes
      threshold = (input.length * 0.25).ceil
      corrections = suggestions.select { |suggestion| suggestion.dl <= threshold }

      return corrections unless corrections.empty?

      # Correct misspells
      suggestions.select do |suggestion|
        length = input.length < suggestion.word.length ? input.length : suggestion.word.length

        suggestion.dl < length
      end
    end

    def suggestion(input) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      input = input.spellr_normalize
      suggestions = suggestions_unsorted(input)
      # correct mistypes
      threshold = (input.length * 0.25).ceil
      correction = suggestions.find { |suggestion| suggestion.dl <= threshold }

      return correction.word if correction

      # Correct misspells
      suggestions.find do |suggestion|
        length = input.length < suggestion.word.length ? input.length : suggestion.word.length

        suggestion.dl < length
      end&.word
    end
  end
end

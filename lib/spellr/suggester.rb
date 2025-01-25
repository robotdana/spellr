# frozen_string_literal: true

require 'jaro_winkler'
require 'damerau-levenshtein'
require_relative 'suggestion'

# This is inspired by and uses parts of ruby's DidYouMean

module Spellr
  module Suggester
    class << self
      def suggestions(token, limit = 5) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        wordlists = token.location.file.wordlists
        term = token.spellr_normalize
        jaro_winkler_similarity_threshold = term.length > 4 ? 0.834 : 0.77
        suggestions = wordlists.flat_map do |wordlist|
          all_suggestions(term, jaro_winkler_similarity_threshold, wordlist)
        end
        suggestions.uniq!(&:word)
        suggestions.sort_by! { |suggestion| [-suggestion.jaro_winkler_similarity, suggestion.word] }

        suggestions = reduce_suggestions(suggestions, term, limit)

        suggestions.map { |suggestion| suggestion.word.send(token.case_method) }
      end

      def slow?
        return @slow if defined?(@slow)

        @slow = ::JaroWinkler.method(:similarity).source_location
      end

      def fast_suggestions(token, limit = 5)
        if slow?
          []
        else
          suggestions(token, limit)
        end
      end

      private

      def all_suggestions(term, jaro_winkler_similarity_threshold, wordlist)
        wordlist.reduce([]) do |acc, word|
          similarity = ::JaroWinkler.similarity(word, term)
          next acc unless similarity >= jaro_winkler_similarity_threshold

          acc << Suggestion.new(word, similarity)
        end
      end

      def reduce_suggestions(suggestions, term, limit = 5)
        candidate_suggestions = reduce_to_mistypes(suggestions, term, limit)
        if candidate_suggestions.empty?
          candidate_suggestions = reduce_to_misspells(suggestions, term, limit)
        end
        reduce_wild_suggestions(candidate_suggestions)
      end

      def reduce_to_mistypes(suggestions, term, limit = 5)
        # Correct mistypes
        threshold = ((term.length - 1) * 0.25).ceil
        suggestions.lazy.select do |suggestion|
          suggestion.levenshtein_distance ||= DamerauLevenshtein.distance(suggestion.word, term)
          suggestion.levenshtein_distance <= threshold
        end.take(limit).to_a
      end

      def reduce_to_misspells(suggestions, term, limit = 1)
        # Correct misspells
        suggestions.lazy.select do |suggestion|
          length = term.length < suggestion.word.length ? term.length : suggestion.word.length

          suggestion.levenshtein_distance ||= DamerauLevenshtein.distance(suggestion.word, term)
          suggestion.levenshtein_distance < length - 1
        end.take(limit).to_a
      end

      def reduce_wild_suggestions(suggestions)
        return suggestions unless suggestions.length > 1

        threshold = suggestions.first.jaro_winkler_similarity * 0.98
        suggestions.select do |suggestion|
          suggestion.jaro_winkler_similarity > threshold
        end
      end
    end
  end
end

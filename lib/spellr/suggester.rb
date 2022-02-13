# frozen_string_literal: true

require 'did_you_mean'
require 'jaro_winkler'

::DidYouMean.send(:remove_const, :JaroWinkler)
::DidYouMean::JaroWinkler = ::JaroWinkler

module Spellr
  class Suggester
    class << self
      def suggestions(token)
        wordlists = token.location.file.wordlists
        term = token.spellr_normalize.chomp
        words = wordlists.flat_map { |wordlist| wordlist.suggestions(token) }.uniq
        words = ::DidYouMean::SpellChecker.new(dictionary: words).correct(term)
        words = reduce_suggestions(words, term)

        words.map { |word| word.send(token.case_method) }
      end

      def slow?
        return @slow if defined?(@slow)

        @slow = ::JaroWinkler.method(:distance).source_location
      end

      def fast_suggestions(token)
        if slow?
          []
        else
          suggestions(token)
        end
      end

      private

      def reduce_suggestions(words, term)
        return words unless words.length > 1

        threshold = ::JaroWinkler.distance(term, words.first) * 0.98
        words.select! { |word| ::JaroWinkler.distance(term, word) > threshold }
        words.sort_by! { |word| [-::JaroWinkler.distance(term, word), word] }
        words.take(5)
      end
    end

    def initialize(wordlist)
      @did_you_mean = ::DidYouMean::SpellChecker.new(dictionary: wordlist.to_a)
      @suggestions = {}
    end

    def suggestions(term)
      term = term.spellr_normalize
      @suggestions.fetch(term) do
        @suggestions[term] = @did_you_mean.correct(term).map(&:chomp)
      end
    end
  end
end

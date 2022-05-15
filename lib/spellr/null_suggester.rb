# frozen_string_literal: true

module Spellr
  class NullSuggester
    class << self
      def suggestions(_token)
        []
      end

      def fast_suggestions(_token)
        []
      end

      def slow?
        true
      end
    end

    def initialize(_wordlist); end

    def suggestions(_term)
      []
    end
  end
end

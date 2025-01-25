# frozen_string_literal: true

module Spellr
  module NullSuggester
    class << self
      def suggestions(_token, _limit = 0)
        []
      end

      def fast_suggestions(_token, _limit = 0)
        []
      end

      def slow?
        true
      end
    end
  end
end

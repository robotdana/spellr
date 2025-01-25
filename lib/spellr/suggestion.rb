# frozen_string_literal: true

class Suggestion
  attr_accessor :levenshtein_distance
  attr_reader :word, :jaro_winkler_similarity

  def initialize(word, jaro_winkler_similarity)
    @word = word
    @jaro_winkler_similarity = jaro_winkler_similarity
  end
end

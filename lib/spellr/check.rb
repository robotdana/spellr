# frozen_string_literal: true

require 'set'
require 'in_threads'
module Spellr
  class Check
    attr_reader :exit_code
    attr_reader :files, :reporter

    def initialize(files: [], reporter: Spellr.config.reporter)
      @files = files
      @reporter = reporter
      @exit_code = 0
    end

    def check # rubocop:disable Metrics/MethodLength
      files.in_threads.map do |file|
        found_words = Set.new
        missed_words = Set.new

        file.each_token do |token, pos|
          if check_token(token, found_words, missed_words, file.dictionaries)
            found_words << token
          else
            missed_words << token
            reporter.call(Spellr::Token.new(token, start: pos, file: file))
            @exit_code = 1
          end
        end
      end
    end

    private

    def check_token(token, found_words, missed_words, dictionaries)
      return true if found_words.include?(token)
      return false if missed_words.include?(token)
      return true if dictionaries.any? { |d| d.include?(token) }

      # TODO: this needs work
      # return false unless Spellr.config.run_together_words?

      # return false if token.length > Spellr.config.run_together_words_maximum_length

      # token.subwords.any? do |subword_set|
      #   subword_set.all? do |subword|
      #     subword_string = subword.to_s.downcase + "\n"
      #     dictionaries.any? { |d| d.bsearch { |value| subword_string <=> value } }
      #   end
      # end
    end
  end
end

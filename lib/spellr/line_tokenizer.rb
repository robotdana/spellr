# frozen_string_literal: true

require 'strscan'
require_relative '../spellr'
require_relative 'column_location'
require_relative 'token'
require_relative 'key_tuner/naive_bayes'
require_relative 'token_regexps'

module Spellr
  class LineTokenizer < StringScanner
    attr_reader :line, :skip_key

    alias_method :skip_key?, :skip_key

    include TokenRegexps

    def initialize(line, skip_key: false)
      @line = line
      @skip_key = skip_key
      @disabled = false

      super(@line.to_s)
    end

    def string=(line)
      @line = line
      super(@line.to_s)
    end

    def each_term
      until eos?
        term = next_term
        next if !term || @disabled

        yield term
      end
    end

    def each_token(skip_if_included: nil) # rubocop:disable Metrics/MethodLength
      until eos?
        term = next_term
        next unless term
        next if @disabled || skip_if_included&.include?(term)

        yield Token.new(term, line: line, location: column_location(term))
      end
    end

    private

    def column_location(term)
      ColumnLocation.new(
        byte_offset: pos - term.bytesize,
        char_offset: charpos - term.length
      )
    end

    def skip_nonwords_and_flags
      skip_nonwords || skip_and_track_enable || skip_and_track_disable
    end

    def next_term
      return if skip_nonwords_and_flags

      scan_term
    end

    def scan_term
      term = scan(TERM_RE)

      return term if term && term.length >= Spellr.config.word_minimum_length
    end

    def skip_nonwords
      skip(SKIPS) || skip_key_heuristically || skip(AFTER_KEY_SKIPS)
    end

    def skip_key_heuristically
      return unless skip_key?

      possible_key = check(POSSIBLE_KEY_RE)

      return unless possible_key
      return unless key?(possible_key)

      self.pos += possible_key.bytesize
    end

    BAYES_KEY_HEURISTIC = NaiveBayes.new
    def key?(possible_key)
      return unless possible_key.length >= Spellr.config.key_minimum_length
      # I've come across some large base64 strings by this point they're definitely base64.
      return true if possible_key.length > 200
      return unless possible_key.match?(min_alpha_re) # or there's no point

      BAYES_KEY_HEURISTIC.key?(possible_key)
    end

    def skip_and_track_disable
      return if @disabled

      skip(SPELLR_DISABLE_RE) && @disabled = true
    end

    def skip_and_track_enable
      return unless @disabled

      skip(SPELLR_ENABLE_RE) && @disabled = false
    end
  end
end

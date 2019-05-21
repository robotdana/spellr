# frozen_string_literal: true

require 'strscan'
require_relative '../spellr'

module Spellr
  class Tokenizer < StringScanner
    attr_reader :line_number
    attr_reader :line_start_pos
    attr_reader :file

    def initialize(string, *loc, file: nil)
      @file = file
      super(string)

      self.charpos = loc[0] || 0
      @line_number = loc[1] || 1
      @line_start_pos = loc[2] || 0
    end

    def tokenize
      require_relative 'token'

      enum_for(:each).map do |token, *loc|
        Spellr::Token.new(token, loc: loc, file: file)
      end
    end

    def each
      until eos?
        start_pos, token = next_token
        next if @disabled
        next unless token
        next if token.length < Spellr.config.word_minimum_length

        yield token, start_pos, line_number, line_start_pos
      end
      reset
    end

    private

    def next_token
      skip_nonwords
      skip_and_track_newline

      skip_and_track_enable
      skip_and_track_disable

      start_pos_and_word
    end

    def start_pos_and_word
      # charpos first because we need the start position of the word
      [charpos, title_case || lower_case || upper_case || other_case]
    end

    NOT_EVEN_NON_WORDS_RE = %r{[^[:alpha:]/#0\n\r\\]+}.freeze # everything not covered by more specific skips/scans
    LEFTOVER_NON_WORD_BITS_RE = %r{[/#0\\]+}.freeze # e.g. a / not starting //a-url.com
    URL_RE = %r{(?://|https?://|s?ftp://|file:///|mailto:)[[:alnum:]%&.@+=/?#_-]+}.freeze # not precise but quick
    HEX_RE = /(?:#|0x)(?:\h{6}|\h{3})/.freeze
    EMAIL_RE = %r{/[[:alnum:]._-]+@[[:alnum:]._-]+/}.freeze # not precise but quick (no looking around)
    BACKSLASH_ESCAPE_RE = /(?:\\\w)+/.freeze # TODO: hex escapes e.g. \xAA. TODO: language aware escapes
    REPEATED_SINGLE_LETTERS_RE = /(?:([[:alpha:]])\1+)(?![[:alpha:]])/.freeze # e.g. xxxxxxxx (it's not a word)
    def skip_nonwords
      skip(NOT_EVEN_NON_WORDS_RE)
      skip(URL_RE)
      skip(HEX_RE)
      skip(EMAIL_RE)
      skip(BACKSLASH_ESCAPE_RE)
      skip(LEFTOVER_NON_WORD_BITS_RE)
      skip(REPEATED_SINGLE_LETTERS_RE)
    end

    # jump to character-aware position
    def charpos=(new_charpos)
      skip(/.{#{new_charpos - charpos}}/m)
    end

    NEWLINE_RE = /\n|\r\n?/.freeze
    def skip_and_track_newline
      return unless skip(NEWLINE_RE)

      @line_start_pos = charpos
      @line_number += 1
    end

    # [Word], [Word]Word [Word]'s [Wordn't]
    TITLE_CASE_RE = /[[:upper:]][[:lower:]]+(?:'[[:lower:]]+(?<!s))*/.freeze
    def title_case
      scan(TITLE_CASE_RE)
    end

    # [word] [word]'s [wordn't]
    LOWER_CASE_RE = /[[:lower:]]+(?:'[[:lower:]]+(?<!s))*/.freeze
    def lower_case
      scan(LOWER_CASE_RE)
    end

    # [WORD] [WORD]Word [WORDN'T] [WORD]'S [WORD]'s
    UPPER_CASE_RE = /[[:upper:]]+(?:'[[:upper:]]+(?<![Ss]))*(?![[:lower:]])/.freeze
    def upper_case
      scan(UPPER_CASE_RE)
    end

    # for characters in [:alpha:] that aren't in [:lower:] or [:upper:] e.g. Arabic
    OTHER_CASE_RE = /[[:alpha:]]+/.freeze
    def other_case
      scan(OTHER_CASE_RE)
    end

    SPELLR_DISABLE_RE = /spellr:disable/.freeze
    def skip_and_track_disable
      skip(SPELLR_DISABLE_RE) && @disabled = true
    end

    SPELLR_ENABLE_RE = /spellr:enable/.freeze
    def skip_and_track_enable
      skip(SPELLR_ENABLE_RE) && @disabled = false
    end
  end
end

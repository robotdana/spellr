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
      skip(%r{[^[:alpha:]/#0-9\n\r\\]+}) # everything that's not covered by further skips
      skip_url
      skip_hex
      skip_email
      skip_backslash_escape
      skip(%r{[/#0-9\\]+}) # everything covered by above
      skip_and_track_newline

      skip_and_track_enable
      skip_and_track_disable

      [charpos, title_case || lower_case || upper_case || other_case]
    end

    # jump to character-aware position
    def charpos=(new_charpos)
      skip(/.{#{new_charpos - charpos}}/m)
    end

    def skip_and_track_newline
      return unless skip(/\n|\r\n?/)

      @line_start_pos = charpos
      @line_number += 1
    end

    # [Word], [Word]Word [Word]'s [Wordn't]
    def title_case
      scan(/[[:upper:]][[:lower:]]+(?:'[[:lower:]]+(?<!s))*/)
    end

    # [word] [word]'s [wordn't]
    def lower_case
      scan(/[[:lower:]]+(?:'[[:lower:]]+(?<!s))*/)
    end

    # [WORD] [WORD]Word [WORDN'T] [WORD]'S [WORD]'s
    def upper_case
      scan(/[[:upper:]]+(?:'[[:upper:]]+(?<![Ss]))*(?![[:lower:]])/)
    end

    # for characters in :alpha: that aren't in :lower: or :upper: e.g. Arabic
    def other_case
      scan(/[[:alpha:]]+/)
    end

    # not a perfect URL regexp, but it is fast
    def skip_url
      skip(%r{(?://|https?://|s?ftp://|file:///|mailto:)[[:alnum:]%&.@+=/?#_-]+})
    end

    # not a perfect email regexp, but it is fast
    def skip_email
      skip(/[[:alnum:]._-]+@[[:alnum:]._-]+/)
    end

    def skip_hex
      skip(/(?:#|0x)(?:\h{6}|\h{3})/)
    end

    def skip_backslash_escape
      skip(/(?:\\\w)+/)
    end

    def skip_and_track_disable
      skip(/spellr:disable/) && @disabled = true
    end

    def skip_and_track_enable
      skip(/spellr:enable/) && @disabled = false
    end
  end
end

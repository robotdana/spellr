# frozen_string_literal: true

require 'strscan'
require_relative '../spellr'

module Spellr
  class Tokenizer < StringScanner # rubocop:disable Metrics/ClassLength
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

      map do |token, *loc|
        Spellr::Token.new(token, loc: loc, file: file)
      end
    end

    def normalize
      require_relative 'token'

      map { |token| Spellr::Token.normalize(token) }
    end

    def words
      map { |x| x }
    end

    def map(&block)
      enum_for(:each).map(&block)
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
      skip_nonwords ||
        skip_and_track_newline ||

        skip_and_track_enable ||
        skip_and_track_disable ||

        start_pos_and_word
    end

    def start_pos_and_word
      # charpos first because we need the start position of the word
      [charpos, title_case || lower_case || upper_case || other_case]
    end

    NOT_EVEN_NON_WORDS_RE = %r{[^[:alpha:]/%#0-9\n\r\\]+}.freeze # everything not covered by more specific skips/scans
    LEFTOVER_NON_WORD_BITS_RE = %r{[/%#0-9\\]}.freeze # e.g. a / not starting //a-url.com
    HEX_RE = /(?:#(?:\h{6}|\h{3})|0x\h+)(?![[:alpha:]])/.freeze
    SHELL_COLOR_ESCAPE_RE = /\\(e|033)\[\d+(;\d+)*m/.freeze
    BACKSLASH_ESCAPE_RE = /\\[a-zA-Z]/.freeze # TODO: hex escapes e.g. \xAA. TODO: language aware escapes
    REPEATED_SINGLE_LETTERS_RE = /(?:([[:alpha:]])\1+)(?![[:alpha:]])/.freeze # e.g. xxxxxxxx (it's not a word)
    # https://developer.mozilla.org/en-US/docs/Glossary/percent-encoding
    # Only the necessary percent encoding that actually ends in letters
    # URL_ENCODED_ENTITIES_RE = /%(3A|2F|3F|5B|5D|%2A|%2B|%2C|%3B|%3D)/i.freeze
    URL_ENCODED_ENTITIES_RE = /%[0-8A-F]{2}/.freeze
    # There's got to be a better way of writing this
    SEQUENTIAL_LETTERS_RE = /a(b(c(d(e(f(g(h(i(j(k(l(m(n(o(p(q(r(s(t(u(v(w(x(y(z)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?(?![[:alpha:]])/i.freeze # rubocop:disable Metrics/LineLength

    def skip_nonwords # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      skip(NOT_EVEN_NON_WORDS_RE) ||
        skip_uri_heuristically ||
        skip_key_heuristically ||
        skip(HEX_RE) ||
        skip(URL_ENCODED_ENTITIES_RE) ||
        skip(SHELL_COLOR_ESCAPE_RE) ||
        skip(BACKSLASH_ESCAPE_RE) ||
        skip(LEFTOVER_NON_WORD_BITS_RE) ||
        skip(REPEATED_SINGLE_LETTERS_RE) ||
        skip(SEQUENTIAL_LETTERS_RE)
    end

    # I didn't want to do this myself. BUT i need something to heuristically match on, and it's difficult
    URL_RE = %r{
      (?<scheme>//|https?://|s?ftp://|mailto:)?
      (?<userinfo>[[:alnum:]]+(?::[[:alnum:]]+)?@)?
      (?<hostname>(?:[[:alnum:]-]+(?:\\?\.[[:alnum:]-]+)+|localhost|\d{1,3}(?:.\d{1,3}){3}))
      (?<port>:\d+)?
      (?<path>/(?:[[:alnum:]=!$&\-/._\\]|%\h{2})+)?
      (?<query>\?(?:[[:alnum:]=!$\-/.\\]|%\h{2})+(?:&(?:[[:alnum:]=!$\-/.\\]|%\h{2})+)*)?
      (?<fragment>\#(?:[[:alnum:]=!$&\-/.\\]|%\h{2})+)?
    }x.freeze
    # unfortunately i have to match this regex a couple times because stringscanner doesn't give me matchdata
    def skip_uri_heuristically
      return unless match?(URL_RE)

      captures = URL_RE.match(matched).named_captures
      skip(URL_RE) if captures['scheme'] || captures['userinfo'] || captures['path']
    end

    # url unsafe base64 or url safe base64
    # TODO: character distribution heuristic
    KEY_FULL_RE = %r{([A-Za-z\d+/]|[A-Za-z\d\-_])+[=.]*}.freeze
    KEY_RE = %r{
      (?:
        [A-Za-z\-_+/=]+|
        [\d\-_+/=]+
      )
    }x.freeze
    def skip_key_heuristically
      return unless match?(KEY_FULL_RE)

      # can't use regular captures because repeated capture groups don't
      matches = matched.scan(KEY_RE)
      return unless matches.length >= 3 # number chosen arbitrarily

      skip(KEY_FULL_RE)
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
    TITLE_CASE_RE = /[[:upper:]][[:lower:]]+(?:['’][[:lower:]]+(?<!['’]s))*/.freeze
    def title_case
      scan(TITLE_CASE_RE)
    end

    # [word] [word]'s [wordn't]
    LOWER_CASE_RE = /[[:lower:]]+(?:['’][[:lower:]]+(?<!['’]s))*/.freeze
    def lower_case
      scan(LOWER_CASE_RE)
    end

    # [WORD] [WORD]Word [WORDN'T] [WORD]'S [WORD]'s [WORD]s
    UPPER_CASE_RE = /[[:upper:]]+(?:['’][[:upper:]]+(?<!['’][Ss]))*((?![[:lower:]])|(?=s(?![[:lower:]])))/.freeze
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

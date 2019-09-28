# frozen_string_literal: true

require 'strscan'
require_relative '../spellr'
require_relative 'column_location'
require_relative 'token'

module Spellr
  class LineTokenizer < StringScanner # rubocop:disable Metrics/ClassLength
    attr_reader :line
    attr_accessor :disabled
    alias_method :disabled?, :disabled
    attr_accessor :skip_uri
    alias_method :skip_uri?, :skip_uri
    attr_accessor :skip_key
    alias_method :skip_key?, :skip_key

    def initialize(*line, skip_uri: true, skip_key: true)
      @line = Spellr::Token.wrap(line.first)
      @skip_uri = skip_uri
      @skip_key = skip_key

      super(@line.to_s)
    end

    def string=(line)
      @line = Token.wrap(line)
      super(@line.to_s)
    end

    def each_term
      until eos?
        term = next_term
        next unless term
        next if disabled?

        yield term
      end
    end

    def each_token
      until eos?
        term = next_term
        next unless term
        next if disabled?

        yield Token.new(term, line: line, location: column_location(term))
      end
    end

    private

    def column_location(term)
      ColumnLocation.new(
        byte_offset: pos - term.bytesize,
        char_offset: charpos - term.length,
        line_location: line.location.line_location
      )
    end

    def skip_nonwords_and_flags
      skip_nonwords || skip_and_track_enable || skip_and_track_disable
    end

    def next_term
      return if eos?

      (skip_nonwords_and_flags && next_term) || scan_term || next_term
    end

    def scan_term
      term = title_case || lower_case || upper_case || other_case

      return term if term && term.length >= Spellr.config.word_minimum_length
    end

    NOT_EVEN_NON_WORDS_RE = %r{[^[:alpha:]/%#0-9\\]+}.freeze # everything not covered by more specific skips/scans
    LEFTOVER_NON_WORD_BITS_RE = %r{[/%#0-9\\]}.freeze # e.g. a / not starting //a-url.com
    HEX_RE = /(?:#(?:\h{6}|\h{3})|0x\h+)(?![[:alpha:]])/.freeze
    SHELL_COLOR_ESCAPE_RE = /\\(?:e|0?33)\[\d+(;\d+)*m/.freeze
    BACKSLASH_ESCAPE_RE = /\\[a-zA-Z]/.freeze # TODO: hex escapes e.g. \xAA. TODO: language aware escapes
    REPEATED_SINGLE_LETTERS_RE = /(?:([[:alpha:]])\1+)(?![[:alpha:]])/.freeze # e.g. xxxxxxxx (it's not a word)
    URL_ENCODED_ENTITIES_RE = /%[0-8A-F]{2}/.freeze
    # There's got to be a better way of writing this
    SEQUENTIAL_LETTERS_RE = /a(?:b(?:c(?:d(?:e(?:f(?:g(?:h(?:i(?:j(?:k(?:l(?:m(?:n(?:o(?:p(?:q(?:r(?:s(?:t(?:u(?:v(?:w(?:x(?:yz?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?(?![[:alpha:]])/i.freeze # rubocop:disable Metrics/LineLength

    def skip_nonwords # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      skip(NOT_EVEN_NON_WORDS_RE) ||
        skip(SHELL_COLOR_ESCAPE_RE) ||
        skip(BACKSLASH_ESCAPE_RE) ||
        skip(URL_ENCODED_ENTITIES_RE) ||
        skip(HEX_RE) ||
        skip_key_heuristically ||
        skip_uri_heuristically ||
        skip(LEFTOVER_NON_WORD_BITS_RE) ||
        skip(REPEATED_SINGLE_LETTERS_RE) ||
        skip(SEQUENTIAL_LETTERS_RE)
    end

    # I didn't want to do this myself. BUT i need something to heuristically match on, and it's difficult
    URL_SCHEME = '(//|https?://|s?ftp://|mailto:)'
    URL_USERINFO = '([[:alnum:]]+(?::[[:alnum:]]+)?@)'
    URL_HOSTNAME = '((?:[[:alnum:]-]+(?:\\\\?\\.[[:alnum:]-]+)+|localhost|\\d{1,3}(?:\\.\\d{1,3}){3}))'
    URL_PORT = '(:\\d+)'
    URL_PATH = '(/(?:[[:alnum:]=@!$&\\-/._\\\\]|%\h{2})+)'
    URL_QUERY = '(\\?(?:[[:alnum:]=!$\\-/.\\\\]|%\\h{2})+(?:&(?:[[:alnum:]=!$\\-/.\\\\]|%\\h{2})+)*)'
    URL_FRAGMENT = '(\\#(?:[[:alnum:]=!$&\\-/.\\\\]|%\\h{2})+)'
    URL_RE = /
      (?:
        #{URL_SCHEME}#{URL_USERINFO}?#{URL_HOSTNAME}#{URL_PORT}?#{URL_PATH}?
        |
        #{URL_SCHEME}?#{URL_USERINFO}#{URL_HOSTNAME}#{URL_PORT}?#{URL_PATH}?
        |
        #{URL_SCHEME}?#{URL_USERINFO}?#{URL_HOSTNAME}#{URL_PORT}?#{URL_PATH}
      )
      #{URL_QUERY}?#{URL_FRAGMENT}?
    /x.freeze
    def skip_uri_heuristically
      return unless skip_uri?

      skip(URL_RE)
    end

    # url unsafe base64 or url safe base64
    # TODO: character distribution heuristic
    KEY_FULL_RE = %r{(?:[A-Za-z\d+/]|[A-Za-z\d\-_])+[=.]*}.freeze
    KEY_RE = %r{
      (?:
        [A-Za-z\-_+/=]+|
        [\d\-_+/=]+
      )
    }x.freeze
    def skip_key_heuristically
      return unless skip_key?
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
    UPPER_CASE_RE = /[[:upper:]]+(?:['’][[:upper:]]+(?<!['’][Ss]))*(?:(?![[:lower:]])|(?=s(?![[:lower:]])))/.freeze
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
      skip(SPELLR_DISABLE_RE) && self.disabled = true
    end

    SPELLR_ENABLE_RE = /spellr:enable/.freeze
    def skip_and_track_enable
      skip(SPELLR_ENABLE_RE) && self.disabled = false
    end
  end
end

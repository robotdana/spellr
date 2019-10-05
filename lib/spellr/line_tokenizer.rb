# frozen_string_literal: true

require 'strscan'
require_relative '../spellr'
require_relative 'column_location'
require_relative 'token'
require_relative 'key_tuner/naive_bayes'

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
      if skip_nonwords_and_flags
        nil
      else
        scan_term
      end
    end

    # [Word], [Word]Word [Word]'s [Wordn't]
    TITLE_CASE_RE = /[[:upper:]][[:lower:]]+(?:['’][[:lower:]]+(?<!['’]s))*/.freeze
    # [WORD] [WORD]Word [WORDN'T] [WORD]'S [WORD]'s [WORD]s
    UPPER_CASE_RE = /[[:upper:]]+(?:['’][[:upper:]]+(?<!['’][Ss]))*(?:(?![[:lower:]])|(?=s(?![[:lower:]])))/.freeze
    # [word] [word]'s [wordn't]
    LOWER_CASE_RE = /[[:lower:]]+(?:['’][[:lower:]]+(?<!['’]s))*/.freeze
    # for characters in [:alpha:] that aren't in [:lower:] or [:upper:] e.g. Arabic
    OTHER_CASE_RE = /(?:[[:alpha:]](?<![[:lower:][:upper:]]))+/.freeze

    TERM_RE = Regexp.union(TITLE_CASE_RE, UPPER_CASE_RE, LOWER_CASE_RE, OTHER_CASE_RE)

    def scan_term
      term = scan(TERM_RE)

      return term if term && term.length >= Spellr.config.word_minimum_length
    end

    NOT_EVEN_NON_WORDS_RE = %r{[^[:alpha:]/%#0-9\\]+}.freeze # everything not covered by more specific skips/scans
    LEFTOVER_NON_WORD_BITS_RE = %r{[/%#\\]|\d+}.freeze # e.g. a / not starting //a-url.com
    HEX_RE = /(?:#(?:\h{6}|\h{3})|0x\h+)(?![[:alpha:]])/.freeze
    SHELL_COLOR_ESCAPE_RE = /\\(?:e|0?33)\[\d+(;\d+)*m/.freeze
    PUNYCODE_RE = /xn--[a-v0-9\-]+(?:[[:alpha:]])/.freeze
    BACKSLASH_ESCAPE_RE = /\\[a-zA-Z]/.freeze # TODO: hex escapes e.g. \xAA. TODO: language aware escapes
    REPEATED_SINGLE_LETTERS_RE = /(?:([[:alpha:]])\1+)(?![[:alpha:]])/.freeze # e.g. xxxxxxxx (it's not a word)
    URL_ENCODED_ENTITIES_RE = /%[0-8A-F]{2}/.freeze
    # There's got to be a better way of writing this
    SEQUENTIAL_LETTERS_RE = /a(?:b(?:c(?:d(?:e(?:f(?:g(?:h(?:i(?:j(?:k(?:l(?:m(?:n(?:o(?:p(?:q(?:r(?:s(?:t(?:u(?:v(?:w(?:x(?:yz?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?(?![[:alpha:]])/i.freeze # rubocop:disable Metrics/LineLength

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

    KNOWN_KEY_PATTERNS_RE = %r{(
      SG\.[\w\-]{22}\.[\w\-]{43} | # sendgrid
      prg-\h{8}-\h{4}-\h{4}-\h{4}-\h{12} | # hyperwallet
      GTM-[A-Z0-9]{7} | # google tag manager
      sha1-[A-Za-z0-9=+/]{28} |
      sha512-[A-Za-z0-9=+/]{88} |
      data:[a-z/;0-9\-]+;base64,[A-Za-z0-9+/]+=*(?![[:alnum:]])
    )}x.freeze

    SKIPS = Regexp.union(
      NOT_EVEN_NON_WORDS_RE,
      SHELL_COLOR_ESCAPE_RE,
      BACKSLASH_ESCAPE_RE,
      URL_ENCODED_ENTITIES_RE,
      HEX_RE,
      URL_RE, # 2%
      KNOWN_KEY_PATTERNS_RE
    ).freeze

    AFTER_KEY_SKIPS = Regexp.union(
      LEFTOVER_NON_WORD_BITS_RE,
      REPEATED_SINGLE_LETTERS_RE,
      SEQUENTIAL_LETTERS_RE
    )

    def skip_nonwords
      skip(SKIPS) ||
        skip_key_heuristically || # 5%
        skip(AFTER_KEY_SKIPS)
    end

    KEY_RE = %r{[A-Za-z0-9]([A-Za-z0-9+/\-_]*)=*(?![[:alnum:]])}.freeze
    N = NaiveBayes.new
    def skip_key_heuristically # rubocop:disable Metrics/MethodLength
      return unless scan(KEY_RE)
      # I've come across some large base64 strings by this point they're definitely base64.
      return true if matched.length > 200

      if key_roughly?(matched)
        if N.key?(matched)
          true
        else
          unscan
          false
        end
      else
        unscan
        false
      end
    end

    # this is in a method becase the minimum word length stuff was throwing it off
    # TODO: move to config maybe?
    def min_alpha_re
      /(?:
        [A-Z][a-z]{#{Spellr.config.word_minimum_length - 1}}
        |
        [a-z]{#{Spellr.config.word_minimum_length}}
        |
        [A-Z]{#{Spellr.config.word_minimum_length}}
      )/x.freeze
    end
    ALPHA_SEP_RE = '[A-Za-z][A-Za-z\\-_/+]*'
    NUM_SEP_RE = '\\d[\\d\\-_/+]*'
    THREE_CHUNK_RE = /^(?:
      #{ALPHA_SEP_RE}#{NUM_SEP_RE}#{ALPHA_SEP_RE}
      |
      #{NUM_SEP_RE}#{ALPHA_SEP_RE}#{NUM_SEP_RE}
    )/x.freeze
    def key_roughly?(matched)
      return unless matched.length >= Spellr.config.key_minimum_length
      return unless matched.match?(THREE_CHUNK_RE)
      return unless matched.match?(min_alpha_re) # or there's no point

      true
    end

    # jump to character-aware position
    def charpos=(new_charpos)
      skip(/.{#{new_charpos - charpos}}/m)
    end

    SPELLR_DISABLE_RE = /spellr:disable/.freeze
    def skip_and_track_disable
      return if disabled?

      skip(SPELLR_DISABLE_RE) && self.disabled = true
    end

    SPELLR_ENABLE_RE = /spellr:enable/.freeze
    def skip_and_track_enable
      return unless disabled?

      skip(SPELLR_ENABLE_RE) && self.disabled = false
    end
  end
end

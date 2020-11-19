# frozen_string_literal: true

require_relative '../spellr'

module Spellr
  module TokenRegexps
    #### WORDS ####

    # [Word], [Word]Word [Word]'s [Wordn't]
    TITLE_CASE_RE = /[[:upper:]][[:lower:]]+(?:['’][[:lower:]]+(?<!['’]s))*/.freeze
    # [WORD] [WORD]Word [WORDN'T] [WORD]'S [WORD]'s [WORD]s
    UPPER_CASE_RE = /[[:upper:]]+(?:['’][[:upper:]]+(?<!['’][Ss]))*(?:(?![[:lower:]])|(?=s(?![[:lower:]])))/.freeze # rubocop:disable Layout/LineLength
    # [word] [word]'s [wordn't]
    LOWER_CASE_RE = /[[:lower:]]+(?:['’][[:lower:]]+(?<!['’]s))*/.freeze
    # for characters in [:alpha:] that aren't in [:lower:] or [:upper:] e.g. Arabic
    OTHER_CASE_RE = /(?:[[:alpha:]](?<![[:lower:][:upper:]]))+/.freeze

    TERM_RE = Regexp.union(TITLE_CASE_RE, UPPER_CASE_RE, LOWER_CASE_RE, OTHER_CASE_RE)

    #### NON WORDS ####

    NOT_EVEN_NON_WORDS_RE = %r{[^[:alpha:]/%#0-9\\]+}.freeze
    LEFTOVER_NON_WORD_BITS_RE = %r{[/%#\\]|\d+}.freeze # e.g. a / not starting //a-url.com
    HEX_RE = /(?:#(?:\h{6}|\h{3})|0x\h+)(?![[:alpha:]])/.freeze
    SHELL_COLOR_ESCAPE_RE = /\\(?:e|0?33)\[\d+(;\d+)*m/.freeze
    # TODO: hex escapes e.g. \xAA.
    # TODO: language aware escapes
    BACKSLASH_ESCAPE_RE = /\\[a-zA-Z]/.freeze
    REPEATED_SINGLE_LETTERS_RE = /(?:([[:alpha:]])\1+)(?![[:alpha:]])/.freeze # e.g. xxxxxxxx
    URL_ENCODED_ENTITIES_RE = /%[0-8A-F]{2}/.freeze
    # There's got to be a better way of writing this
    SEQUENTIAL_LETTERS_RE = /a(?:b(?:c(?:d(?:e(?:f(?:g(?:h(?:i(?:j(?:k(?:l(?:m(?:n(?:o(?:p(?:q(?:r(?:s(?:t(?:u(?:v(?:w(?:x(?:yz?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?(?![[:alpha:]])/i.freeze # rubocop:disable Layout/LineLength

    # I didn't want to do this myself
    # BUT i need something to heuristically match on, and it's difficult
    URL_SCHEME = %r{(?://|https?://|s?ftp://|mailto:)}.freeze
    URL_USERINFO = /[[:alnum:]]+(?::[[:alnum:]]+)?@/.freeze
    URL_IP_ADDRESS = /\d{1,3}(?:\.\d{1,3}){3}/.freeze
    # literal \ so that i can match on domains in regexps. no-one cares but me.
    URL_HOSTNAME = /(?:[[:alnum:]\-\\]+(?:\.[[:alnum:]\-\\]+)+|localhost|#{URL_IP_ADDRESS})/.freeze
    URL_PORT = /:\d+/.freeze
    URL_PATH = %r{/(?:[[:alnum:]=@!$&~\-/._\\]|%\h{2})+}.freeze
    URL_QUERY = %r{\?(?:[[:alnum:]=!$\-/.\\]|%\h{2})+(?:&(?:[[:alnum:]=!$\-/.\\]|%\h{2})+)*}.freeze
    URL_FRAGMENT = %r{#(?:[[:alnum:]=!$&\-/.\\]|%\h{2})+}.freeze

    # URL can be any valid hostname, it must have either a scheme, userinfo, or path
    # it may have those and any of the others and a port, or a query or a fragment.
    URL_REST = /#{URL_QUERY}?#{URL_FRAGMENT}?/.freeze
    URL_RE = Regexp.union(
      /#{URL_SCHEME}#{URL_USERINFO}?#{URL_HOSTNAME}#{URL_PORT}?#{URL_PATH}?#{URL_REST}/,
      /#{URL_USERINFO}#{URL_HOSTNAME}#{URL_PORT}?#{URL_PATH}?#{URL_REST}/,
      /#{URL_HOSTNAME}#{URL_PORT}?#{URL_PATH}#{URL_REST}/
    ).freeze

    KEY_SENDGRID_RE = /SG\.[\w\-]{22}\.[\w\-]{43}/.freeze
    KEY_HYPERWALLET_RE = /prg-\h{8}-\h{4}-\h{4}-\h{4}-\h{12}/.freeze
    KEY_GTM_RE = /GTM-[A-Z0-9]{7}/.freeze
    KEY_SHA1 = %r{sha1-[A-Za-z0-9=+/]{28}}.freeze
    KEY_SHA512 = %r{sha512-[A-Za-z0-9=;+/]{88}}.freeze
    KEY_DATA_URL = %r{data:[a-z/;0-9\-]+;base64,[A-Za-z0-9+/]+=*(?![[:alnum:]])}.freeze

    KEY_PATTERNS_RE = Regexp.union(
      KEY_SENDGRID_RE, KEY_HYPERWALLET_RE, KEY_GTM_RE, KEY_SHA1, KEY_SHA512, KEY_DATA_URL
    )

    SKIPS = Regexp.union(
      NOT_EVEN_NON_WORDS_RE,
      SHELL_COLOR_ESCAPE_RE,
      BACKSLASH_ESCAPE_RE,
      URL_ENCODED_ENTITIES_RE,
      HEX_RE,
      URL_RE, # 2%
      KEY_PATTERNS_RE
    ).freeze

    AFTER_KEY_SKIPS = Regexp.union(
      LEFTOVER_NON_WORD_BITS_RE,
      REPEATED_SINGLE_LETTERS_RE,
      SEQUENTIAL_LETTERS_RE
    )

    # this is in a method because the minimum word length stuff was throwing it off
    # TODO: move to config maybe?
    def min_alpha_re
      @min_alpha_re ||= Regexp.union(
        /[A-Z][a-z]{#{Spellr.config.word_minimum_length - 1}}/,
        /[a-z]{#{Spellr.config.word_minimum_length}}/,
        /[A-Z]{#{Spellr.config.word_minimum_length}}/
      ).freeze
    end
    ALPHA_SEP_RE = %r{[A-Za-z][A-Za-z\-_/+]*}.freeze
    NUM_SEP_RE = %r{\d[\d\-_/+]*}.freeze
    THREE_CHUNK_RE = Regexp.union(
      /\A#{ALPHA_SEP_RE}#{NUM_SEP_RE}#{ALPHA_SEP_RE}/,
      /\A#{NUM_SEP_RE}#{ALPHA_SEP_RE}#{NUM_SEP_RE}/
    ).freeze
    POSSIBLE_KEY_RE = %r{#{THREE_CHUNK_RE}[A-Za-z0-9+/\-_]*=*(?![[:alnum:]])}.freeze

    SPELLR_DISABLE_RE = /spellr:disable/.freeze
    SPELLR_ENABLE_RE = /spellr:enable/.freeze
    SPELLR_LINE_DISABLE_RE = /spellr:disable[-:]line/.freeze
  end
end

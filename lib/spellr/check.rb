# frozen_string_literal: true

require_relative '../spellr'
require_relative 'tokenizer'
require_relative 'token'
require_relative 'column_location'
require_relative 'line_location'

module Spellr
  class InvalidByteSequence
    def self.===(error)
      error.is_a?(ArgumentError) &&
        /invalid byte sequence/.match?(error.message)
    end
  end

  class Check
    attr_reader :exit_code
    attr_reader :files, :reporter

    def initialize(files: [], reporter: Spellr.config.reporter)
      @files = files
      @reporter = reporter
      @exit_code = 0
    end

    def check
      checked = 0
      files.each do |file|
        check_file(file)
        checked += 1
      end

      reporter.finish(checked) if reporter.respond_to?(:finish)
    end

    private

    def check_file(file, start_at: nil, wordlists: Spellr.config.wordlists_for(file)) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      restart_token = catch(:check_file_from) do
        Spellr::Tokenizer.new(file, start_at: start_at).each_token do |token|
          next if wordlists.any? { |d| d.include?(token) }

          start_at = token.location
          reporter.call(token)
          @exit_code = 1
        end
        nil
      end
      if restart_token
        wordlist_arg = restart_token.replacement ? { wordlists: wordlists } : {} # new wordlist cache when adding a word
        check_file(file, start_at: restart_token.location, **wordlist_arg)
      end
    rescue InvalidByteSequence
      # sometimes files are binary
      warn "Skipped unreadable file: #{file}" unless Spellr.config.quiet?
    end
  end
end

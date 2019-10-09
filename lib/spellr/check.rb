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
      @checked = 0
    end

    def check
      files.each do |file|
        check_and_count_file(file)
      end

      reporter.finish(@checked) if reporter.respond_to?(:finish)
    end

    private

    def check_and_count_file(file)
      check_file(file)
      @checked += 1
    rescue InvalidByteSequence
      # sometimes files are binary
      warn "Skipped unreadable file: #{file}" unless Spellr.config.quiet?
    end

    def check_tokens_in_file(file, start_at, wordlist_proc)
      Spellr::Tokenizer.new(file, start_at: start_at)
        .each_token(skip_term_proc: wordlist_proc) do |token|
          reporter.call(token)
          @exit_code = 1
        end
    end

    def wordlist_proc_for(file)
      wordlists = Spellr.config.wordlists_for(file)

      ->(term) { wordlists.any? { |w| w.include?(term) } }
    end

    def check_file_from_restart(file, restart_token, wordlist_proc)
      # new wordlist cache when adding a word
      wordlist_proc = wordlist_proc_for(file) unless restart_token.replacement
      check_file(file, start_at: restart_token.location, wordlist_proc: wordlist_proc)
    end

    def check_file(file, start_at: nil, wordlist_proc: wordlist_proc_for(file))
      restart_token = catch(:check_file_from) do
        check_tokens_in_file(file, start_at, wordlist_proc)
        nil
      end
      check_file_from_restart(file, restart_token, wordlist_proc) if restart_token
    end
  end
end

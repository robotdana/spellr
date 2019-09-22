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

    def check_file(file, start_at: nil, wordlists: Spellr.config.wordlists_for(file)) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/LineLength
      Spellr::Tokenizer.new(file, start_at: start_at).each_token do |token|
        next if wordlists.any? { |d| d.include?(token) }

        start_at = token.location
        reporter.call(token)
        @exit_code = 1
      end
    rescue Spellr::DidReplacement => e # Yeah this is exceptions for control flow, but it makes sense to me
      check_file(file, start_at: e.token.location, wordlists: wordlists)
    rescue Spellr::DidAdd => e
      check_file(file, start_at: e.token.location) # don't cache the wordlists
    rescue InvalidByteSequence
      # sometimes files are binary
      puts "Skipped unreadable file: #{file}" unless Spellr.config.quiet?
    end
  end
end

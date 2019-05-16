# frozen_string_literal: true

require_relative '../spellr'
require_relative 'tokenizer'
require_relative 'token'

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
      rescue InvalidByteSequence
        # sometimes files are binary
        puts "Skipped unreadable file: #{file}" unless Spellr.config.quiet?
      end

      reporter.finish(checked) if reporter.respond_to?(:finish)
    end

    private

    def check_file(file, start_loc: nil, wordlists: Spellr.config.wordlists_for(file))
      Spellr::Tokenizer.new(file.read, *start_loc).each do |token, *loc|
        next if wordlists.any? { |d| d.include?(token) }

        reporter.call(Spellr::Token.new(token, file: file, loc: loc))
        @exit_code = 1
      rescue Spellr::DidReplacement # Yeah this is exceptions for control flow, but it makes sense to me
        check_file(file, start_loc: loc, wordlists: wordlists)
      end
    end
  end
end

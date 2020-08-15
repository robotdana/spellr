# frozen_string_literal: true

require_relative '../spellr'
require_relative 'tokenizer'
require_relative 'string_format'
require_relative 'wordlist_set'

module Spellr
  class Check
    attr_reader :files, :reporter

    include StringFormat

    def exit_code
      reporter.exit_code
    end

    def initialize(files: [], reporter: Spellr.config.reporter)
      @files = files

      @reporter = reporter
    end

    def check
      files.each do |file|
        check_and_count_file(file)
      end

      reporter.finish
    end

    private

    def check_and_count_file(file)
      check_file(file)
      reporter.output.increment(:checked)
    rescue Spellr::InvalidByteSequence
      # sometimes files are binary
      reporter.warn "Skipped unreadable file: #{aqua file.relative_path}"
    end

    def check_file(file, start_at = nil, wordlist_set = ::Spellr::WordlistSet.for_file(file))
      Spellr::Tokenizer.new(file, start_at: start_at)
        .each_token(skip_if_included: wordlist_set) do |token|
          reporter.call(token)
          reporter.output.exit_code = 1
        end
    end
  end
end

# frozen_string_literal: true

require_relative '../spellr'
require_relative 'tokenizer'

module Spellr
  class Check
    attr_reader :files, :reporter

    def exit_code
      reporter.exit_code
    end

    def initialize(files: [], reporter: Spellr.config.reporter)
      @files = files

      @main_reporter = @reporter = reporter
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
      reporter.warn "Skipped unreadable file: #{file}"
    end

    def check_file(file, start_at = nil, found_word_proc = wordlist_proc_for(file))
      Spellr::Tokenizer.new(file, start_at: start_at)
        .each_token(skip_term_proc: found_word_proc) do |token|
          reporter.call(token)
          reporter.output.exit_code = 1
        end
    end

    def wordlist_proc_for(file)
      wordlists = Spellr.config.wordlists_for(file).sort_by(&:length).reverse

      ->(term) { wordlists.any? { |w| w.include?(term) } }
    end
  end
end

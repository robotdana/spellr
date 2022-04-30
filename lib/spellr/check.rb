# frozen_string_literal: true

require_relative '../spellr'
require_relative 'tokenizer'
require_relative 'string_format'
require_relative 'output_stubbed'

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
      if Spellr.config.parallel
        parallel_check
      else
        files.each { |file| check_and_count_file(file, reporter) }
      end

      reporter.finish
    end

    private

    def parallel_check
      require 'parallel'

      Parallel.each(files, finish: ->(_, _, result) { reporter.output << result }) do |file|
        sub_reporter = reporter.class.new(Spellr::OutputStubbed.new)
        check_and_count_file(file, sub_reporter)
        sub_reporter.output
      end
    end

    def check_and_count_file(file, current_reporter)
      check_file(file, current_reporter)
      current_reporter.output.increment(:checked)
    rescue Spellr::InvalidByteSequence, ::Errno::ENOENT, ::Errno::EISDIR, ::Errno::EACCES
      current_reporter.warn "Skipped unreadable file: #{aqua file.relative_path}"
    end

    def check_file(file, curr_reporter, start_at = nil, wordlist_proc = wordlist_proc_for(file))
      restart_token = catch(:check_file_from) do
        report_file(file, curr_reporter, start_at, wordlist_proc)
        nil
      end
      check_file_from_restart(file, curr_reporter, restart_token, wordlist_proc) if restart_token
    end

    def report_file(file, curr_reporter, start_at = nil, wordlist_proc = wordlist_proc_for(file))
      Spellr::Tokenizer.new(file, start_at: start_at)
        .each_token(skip_term_proc: wordlist_proc) do |token|
          curr_reporter.call(token)
          curr_reporter.output.exit_code = 1
        end
    end

    def check_file_from_restart(file, current_reporter, restart_token, wordlist_proc)
      # new wordlist cache when adding a word
      wordlist_proc = wordlist_proc_for(file) unless restart_token.replacement
      check_file(file, current_reporter, restart_token.location, wordlist_proc)
    end

    def wordlist_proc_for(file)
      wordlists = file.wordlists

      ->(term) { wordlists.any? { |w| w.include?(term) } }
    end
  end
end

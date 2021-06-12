# frozen_string_literal: true

require 'pathname'
require_relative '../spellr'
require_relative 'cli_options'
require_relative 'string_format'

module Spellr
  class CLI
    def initialize(argv)
      Spellr.config.reset!
      @argv = argv
    end

    def run
      catch(:spellr_exit) { run_subcommand }
    rescue Spellr::Error => e
      Spellr.config.output.warn(Spellr::StringFormat.red(e.message))
      1
    end

    private

    def run_subcommand
      CLI::Options.parse(@argv)
      Spellr.config.valid?
      exit_code = check
      exit_code = prune if exit_code.zero? && Spellr.config.prune_wordlists?
      exit_code
    end

    def check
      checker = Spellr.config.checker.new(files: Spellr.config.file_list)
      checker.check

      checker.exit_code
    end

    def prune
      require_relative 'prune'
      Spellr.config.output.puts ''
      Spellr::Prune.run
    end
  end
end

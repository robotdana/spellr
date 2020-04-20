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
      catch(:spellr_exit) { check }
    rescue Spellr::Error => e
      Spellr.config.output.warn(Spellr::StringFormat.red(e.message)) && 1
      1
    end

    private

    def check
      CLI::Options.parse(@argv)
      Spellr.config.valid?
      checker = Spellr.config.checker.new(files: files)
      checker.check

      checker.exit_code
    end

    def files
      require_relative 'file_list'
      Spellr::FileList.new(@argv)
    end
  end
end

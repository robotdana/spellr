# frozen_string_literal: true

require_relative '../spellr'
require_relative 'cli_options'
require_relative 'string_format'

module Spellr
  class CLI
    def initialize(argv)
      @argv = argv
      CLI::Options.parse(@argv)
      check
    rescue Spellr::Error => e
      exit_with_error(e.message)
    end

    def exit_with_error(message)
      warn Spellr::StringFormat.red(message)
      exit 1
    end

    def check
      Spellr.config.valid?
      checker = Spellr.config.checker.new(files: files)
      checker.check

      exit checker.exit_code
    end

    def files
      require_relative 'file_list'
      Spellr::FileList.new(@argv)
    end
  end
end

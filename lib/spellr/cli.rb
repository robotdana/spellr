# frozen_string_literal: true

require_relative '../spellr'
require_relative 'cli_options'
require_relative 'string_format'

module Spellr
  class CLI
    attr_reader :argv

    def initialize(argv)
      @argv = argv

      CLI::Options.parse(@argv)

      run
    end

    def run
      validate_config

      check
    rescue Spellr::Error => e
      warn red("Error: #{e.message}")
      exit 1
    end

    def check
      checker = Spellr.config.checker.new(files: files)
      checker.check

      exit checker.exit_code
    end

    def validate_config
      return true if Spellr.config.valid?

      Spellr.config.print_errors
      exit 1
    end

    def files
      require_relative 'file_list'
      Spellr::FileList.new(argv)
    end
  end
end

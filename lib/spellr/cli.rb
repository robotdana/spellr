# frozen_string_literal: true

require_relative '../spellr'
require_relative 'cli_options'

module Spellr
  class CLI
    attr_reader :argv

    def initialize(argv)
      @argv = argv
      CLI::Options.parse(@argv)
      Spellr.config.valid?
    end

    def check
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

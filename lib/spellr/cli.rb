# frozen_string_literal: true

require 'optparse'
require_relative '../spellr'

module Spellr
  class CLI
    def initialize # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      OptionParser.new do |opts| # rubocop:disable Metrics/BlockLength
        opts.on('-w', '--wordlist', 'Outputs errors in wordlist format') do
          require_relative 'wordlist_reporter'
          Spellr.config.reporter = Spellr::WordlistReporter.new
        end

        opts.on('-q', '--quiet', 'Silences all output') do
          Spellr.config.quiet = true
          Spellr.config.reporter = ->(_) {}
        end

        opts.on('-i', '--interactive', 'Runs the spell check interactively') do
          require_relative 'interactive'
          Spellr.config.reporter = Spellr::Interactive.new
        end
        opts.on('-c', '--config FILENAME', String, 'Path to the config file') do |file|
          Spellr.config.config_file = file
        end
        opts.on_tail('-l', '--list', 'List files to be spellchecked') do
          files.each { |f| puts f.relative_path_from(Pathname.pwd) }

          exit
        end
        opts.on_tail('-v', '--version', 'Returns the current version') do
          require_relative 'version'
          puts(Spellr::VERSION)

          exit
        end
        opts.on_tail('-h', '--help', 'Shows this message') do
          puts(opts)

          exit
        end
      end.parse!

      require_relative 'check'
      checker = Spellr::Check.new(files: files)
      checker.check

      exit checker.exit_code
    end

    def files
      require_relative 'file_list'
      Spellr::FileList.new(*ARGV)
    end
  end
end

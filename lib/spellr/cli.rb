# frozen_string_literal: true

require 'optparse'
require 'pathname'
require 'open3'

require_relative '../spellr'

module Spellr
  class CLI
    attr_reader :argv

    def initialize(argv)
      @argv = argv

      parse_command
    end

    def check
      require_relative 'check'
      unless Spellr.config.valid?
        Spellr.config.print_errors
        exit 1
      end

      checker = Spellr::Check.new(files: files)
      checker.check

      exit checker.exit_code
    end

    def files
      require_relative 'file_list'
      Spellr::FileList.new(*argv)
    end

    def wordlist_option(_)
      require_relative 'wordlist_reporter'
      Spellr.config.reporter = Spellr::WordlistReporter.new
    end

    def quiet_option(_)
      Spellr.config.quiet = true
      Spellr.config.reporter = ->(_) {}
    end

    def interactive_option(_)
      require_relative 'interactive'
      Spellr.config.reporter = Spellr::Interactive.new
    end

    def config_option(file)
      Spellr.config.config_file = Pathname.pwd.join(file).expand_path
    end

    def dry_run_option(_)
      files.each { |f| puts f.relative_path_from(Pathname.pwd) }

      exit
    end

    def version_option(_)
      require_relative 'version'
      puts(Spellr::VERSION)

      exit
    end

    def parse_command
      parse_options
      check
    end

    def options_help(_)
      puts options.help

      exit
    end

    def parse_options
      options.parse!(argv)
    end

    def options # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      @options ||= begin
        opts = OptionParser.new

        opts.banner = 'Usage: spellr [options] [files]'
        opts.separator('')
        opts.on('-w', '--wordlist', 'Outputs errors in wordlist format', &method(:wordlist_option))
        opts.on('-q', '--quiet', 'Silences output', &method(:quiet_option))
        opts.on('-i', '--interactive', 'Runs the spell check interactively', &method(:interactive_option))
        opts.separator('')
        opts.on('-d', '--dry-run', 'List files to be checked', &method(:dry_run_option))
        opts.separator('')
        opts.on('-c', '--config FILENAME', String, <<~HELP, &method(:config_option))
          Path to the config file (default ./.spellr.yml)
        HELP
        opts.on('-v', '--version', 'Returns the current version', &method(:version_option))
        opts.on('-h', '--help', 'Shows this message', &method(:options_help))

        opts
      end
    end
  end
end

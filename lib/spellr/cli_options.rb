# frozen_string_literal: true

require 'optparse'
require 'pathname'
require_relative '../spellr'

module Spellr
  class CLI
    class Options
      class << self
        def parse(argv)
          @parallel_option = false

          options.parse!(argv)
        end

        private

        # rubocop:disable Layout/LineLength
        def options # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
          opts = OptionParser.new

          opts.banner = 'Usage: spellr [options] [files]'
          opts.separator('')
          opts.on('-w', '--wordlist', 'Outputs errors in wordlist format', &method(:wordlist_option))
          opts.on('-q', '--quiet', 'Silences output', &method(:quiet_option))
          opts.on('-i', '--interactive', 'Runs the spell check interactively', &method(:interactive_option))
          opts.separator('')
          opts.on('--[no-]parallel', 'Run in parallel or not, default --parallel', &method(:parallel_option))
          opts.on('-d', '--dry-run', 'List files to be checked', &method(:dry_run_option))
          opts.separator('')
          opts.on('-c', '--config FILENAME', String, <<~HELP, &method(:config_option))
            Path to the config file (default ./.spellr.yml)
          HELP
          opts.on('-v', '--version', 'Returns the current version', &method(:version_option))
          opts.on('-h', '--help', 'Shows this message', &method(:options_help))

          opts
        end
        # rubocop:enable Layout/LineLength

        def wordlist_option(_)
          require_relative 'wordlist_reporter'
          Spellr.config.reporter = Spellr::WordlistReporter.new
        end

        def quiet_option(_)
          require_relative 'quiet_reporter'
          Spellr.config.reporter = Spellr::QuietReporter.new
        end

        def interactive_option(_)
          require_relative 'interactive'
          require_relative 'check_interactive'
          Spellr.config.reporter = Spellr::Interactive.new
          Spellr.config.checker = Spellr::CheckInteractive unless @parallel_option
        end

        def config_option(file)
          file = Spellr.pwd.join(file).expand_path

          unless ::File.readable?(file)
            raise Spellr::Config::NotFound, "Config error: #{file} not found or not readable"
          end

          Spellr.config.config_file = file
        end

        def parallel_option(parallel) # rubocop:disable Metrics/MethodLength
          @parallel_option = true
          Spellr.config.checker = if parallel
            require_relative 'check_parallel'
            Spellr::CheckParallel
          else
            require_relative 'check'
            Spellr::Check
          end
        end

        def dry_run_option(_)
          Spellr.config.dry_run = true
        end

        def version_option(_)
          require_relative 'version'
          Spellr.config.output.puts(Spellr::VERSION)

          Spellr.exit
        end

        def options_help(_)
          Spellr.config.output.puts options.help

          Spellr.exit
        end
      end
    end
  end
end

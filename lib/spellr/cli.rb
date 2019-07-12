# frozen_string_literal: true

require 'optparse'
require 'pathname'
require 'open3'

require_relative '../spellr'

module Spellr
  class CLI # rubocop:disable Metrics/ClassLength
    attr_writer :fetch_output_dir
    attr_reader :argv

    def initialize(argv)
      @argv = argv

      parse_command
    end

    def check
      require_relative 'check'
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

    def get_wordlist_option(command)
      get_wordlist_dir.join(command)
    end

    def fetch_output_dir
      @fetch_output_dir ||= Pathname.pwd.join('.spellr_wordlists/generated').expand_path
    end

    def fetch_words_for_wordlist(wordlist)
      wordlist_command(wordlist, *argv)
    end

    def wordlist_command(wordlist, *args)
      require 'shellwords'
      command = fetch_wordlist_dir.join(wordlist).to_s
      fetch_output_dir.mkpath

      command_with_args = args.unshift(command).shelljoin

      out, err, status = Open3.capture3(command_with_args)
      puts err unless err.empty?
      return out if status.exitstatus == 0

      exit
    end

    def replace_wordlist(words, wordlist)
      require_relative '../../lib/spellr/wordlist'

      Spellr::Wordlist.new(fetch_output_dir.join("#{wordlist}.txt")).clean(StringIO.new(words))
    end

    def extract_and_write_license(words, wordlist)
      words, license = words.split('---', 2).reverse

      fetch_output_dir.join("#{wordlist}.LICENSE.txt").write(license) if license

      words
    end

    def fetch
      wordlist = argv.shift
      puts "Fetching #{wordlist} wordlist"
      words = fetch_words_for_wordlist(wordlist)
      puts "Preparing #{wordlist} wordlist"
      words = extract_and_write_license(words, wordlist)
      puts "cleaning #{wordlist} wordlist"
      replace_wordlist(words, wordlist)

      exit
    end

    def output_option(dir)
      self.fetch_output_dir = Pathname.pwd.join(dir).expand_path
    end

    def wordlists
      fetch_wordlist_dir.children.map { |p| p.basename.to_s }
    end

    def fetch_wordlist_dir
      @fetch_wordlist_dir ||= Pathname.new(__dir__).parent.parent.join('bin', 'fetch_wordlist').expand_path
    end

    def parse_command
      case argv.first
      when 'fetch'
        parse_fetch_options
        fetch
      else
        parse_options
        check
      end
    end

    def fetch_options
      @fetch_options ||= begin
        opts = OptionParser.new
        opts.banner = "Usage: spellr fetch [options] WORDLIST [wordlist options]\nAvailable wordlists: #{wordlists}"

        opts.separator('')
        opts.on('-o', '--output=OUTPUT', 'Outputs the fetched wordlist to OUTPUT/WORDLIST.txt', &method(:output_option))
        opts.on('-h', '--help', 'Shows help for fetch', &method(:fetch_options_help))

        opts
      end
    end

    def fetch_options_help(*_)
      puts fetch_options.help

      wordlist = argv.first
      if wordlist
        puts
        wordlist_command('english', '--help')
      end

      exit
    end

    def options_help(_)
      puts options.help
      puts
      puts fetch_options.help

      exit
    end

    def parse_options
      options.parse!(argv)
    end

    def parse_fetch_options
      argv.shift
      fetch_options.order!(argv) do |non_arg|
        argv.unshift(non_arg)
        break
      end
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

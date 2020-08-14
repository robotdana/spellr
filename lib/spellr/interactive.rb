# frozen_string_literal: true

require 'io/console'
require_relative '../spellr'
require_relative 'interactive_add'
require_relative 'interactive_replacement'
require_relative 'base_reporter'

module Spellr
  class Interactive < BaseReporter # rubocop:disable Metrics/ClassLength
    def finish # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      puts "\n"
      puts "#{pluralize 'file', counts[:checked]} checked"
      puts "#{pluralize 'error', total} found"
      if counts[:total_skipped].positive?
        puts "#{pluralize 'error', counts[:total_skipped]} skipped"
      end
      puts "#{pluralize 'error', counts[:total_fixed]} fixed" if counts[:total_fixed].positive?
      puts "#{pluralize 'word', counts[:total_added]} added" if counts[:total_added].positive?
    end

    def global_replacements
      @global_replacements ||= counts[:global_replacements] = {}
    end

    def global_skips
      @global_skips ||= counts[:global_skips] = []
    end

    def call(token)
      # if attempt_global_replacement succeeds, then it throws,
      # it acts like a guard clause all by itself.
      attempt_global_replacement(token)
      return if attempt_global_skip(token)

      super

      prompt(token)
    end

    def prompt_for_key
      print "[ ]\e[2D"
    end

    def loop_within(seconds) # rubocop:disable Metrics/MethodLength
      # timeout is just because it gets stuck sometimes
      Timeout.timeout(seconds * 10) do
        start_time = monotonic_time
        yield until start_time + seconds < monotonic_time
      end
    rescue Timeout::Error
      # :nocov:
      nil
      # :nocov:
    end

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def stdin_getch(legal_chars) # rubocop:disable Metrics/MethodLength
      choice = output.stdin.getch

      if legal_chars.include?(choice)
        puts "\e[0K#{bold print_keypress(choice)}]\e[1C"
        choice
      elsif choice == "\e" # mac sends \e[A when up is pressed. thanks.
        print "\a"
        loop_within(0.001) { output.stdin.getch }

        stdin_getch(legal_chars)
      else
        print "\a"
        stdin_getch(legal_chars)
      end
    end

    ALPHABET = ('A'..'Z').to_a.join
    CTRL = ("\u0001".."\u0026").freeze
    CTRL_STR = CTRL.to_a.join
    def print_keypress(char)
      return char unless CTRL.cover?(char)

      "^#{char.tr(CTRL_STR, ALPHABET)}"
    end

    def prompt(token)
      print "#{key 'add'}, #{key 'replace'}, #{key 'skip'}, #{key 'help'}, [^#{bold 'C'}] to exit: "
      prompt_for_key

      handle_response(token)
    end

    def clear_line(lines = 1)
      print "\r\e[K"
      (lines - 1).times do
        sleep 0.01
        print "\r\e[1T\e[2K"
      end
    end

    private

    def total
      counts[:total_skipped] + counts[:total_fixed] + counts[:total_added]
    end

    def attempt_global_skip(token)
      return unless global_skips.include?(token.to_s)

      puts "Automatically skipped #{red(token)}"
      increment(:total_skipped)
    end

    def attempt_global_replacement(token, replacement = global_replacements[token.to_s])
      return unless replacement

      token.replace(replacement)
      increment(:total_fixed)
      puts "Automatically replaced #{red(token)} with #{green(replacement)}"
      throw :check_file_from, token
    end

    def handle_response(token) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
      # :nocov:
      case stdin_getch("qaAsSrR?h\u0003\u0004")
      # :nocov:
      when 'q', "\u0003" # ctrl c
        Spellr.exit 1
      when 'a', 'A'
        Spellr::InteractiveAdd.new(token, self)
      when 's', "\u0004" # ctrl d
        handle_skip(token)
      when 'S'
        handle_skip(token) { |skip_token| global_skips << skip_token.to_s }
      when 'R'
        Spellr::InteractiveReplacement.new(token, self).global_replace
      when 'r'
        Spellr::InteractiveReplacement.new(token, self).replace
      when '?', 'h'
        handle_help(token)
      end
    end

    def handle_skip(token)
      increment(:total_skipped)
      yield token if block_given?
      puts "Skipped #{red(token)}"
    end

    def handle_help(token) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      clear_line(2)
      puts ''
      puts "#{key 'a'} Add #{red token} to a word list"
      puts "#{key 'r'} Replace #{red token}"
      puts "#{key 'R'} Replace this and all future instances of #{red token}"
      puts "#{key 's'} Skip #{red token}"
      puts "#{key 'S'} Skip this and all future instances of #{red token}"
      puts "#{key 'h'} Show this help"
      puts "[ctrl] + #{key 'C'} Exit spellr"
      puts ''
      print "What do you want to do? [ ]\e[2D"
      handle_response(token)
    end
  end
end

# frozen_string_literal: true

require 'io/console'
require_relative '../spellr'
require_relative 'interactive_add'
require_relative 'interactive_replacement'
require_relative 'base_reporter'
require_relative 'maybe_suggester'

module Spellr
  class Interactive < BaseReporter # rubocop:disable Metrics/ClassLength
    def finish
      warn "\n"
      print_count(:checked, 'file')
      print_value(total, 'error', 'found')
      print_count(:total_skipped, 'error', 'skipped', hide_zero: true)
      print_count(:total_fixed, 'error', 'fixed', hide_zero: true)
      print_count(:total_added, 'word', 'added', hide_zero: true)
    end

    def global_replacements
      @global_replacements ||= counts[:global_replacements] = {}
    end

    def global_skips
      @global_skips ||= counts[:global_skips] = []
    end

    def call(token, only_prompt: false)
      # if attempt_global_replacement succeeds, then it throws,
      # it acts like a guard clause all by itself.
      attempt_global_replacement(token)
      return if attempt_global_skip(token)

      super(token) unless only_prompt

      suggestions = ::Spellr::Suggester.fast_suggestions(token, 5)
      print_suggestions(suggestions) unless only_prompt

      prompt(token, suggestions)
    end

    def prompt_for_key
      print "[ ]\e[2D"
    end

    def loop_within(seconds)
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

    def print_suggestions(suggestions)
      return if suggestions.empty?

      puts "Did you mean: #{number_suggestions(suggestions)}"
    end

    def number_suggestions(suggestions)
      suggestions.map.with_index(1) { |word, i| "#{key i.to_s} #{word}" }.join(', ')
    end

    def prompt(token, suggestions)
      print "#{key 'add'}, #{key 'replace'}, #{key 'skip'}, #{key 'help'}, [^#{bold 'C'}] to exit: "
      prompt_for_key

      handle_response(token, suggestions)
    end

    def clear_line(lines = 1)
      print "\r\e[K"
      (lines - 1).times do
        sleep 0.01
        print "\r\e[0m\e[1T\e[2K"
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

    def suggestions_options(suggestions)
      return suggestions if suggestions.empty?

      ('1'..(suggestions.length.to_s)).to_a
    end

    def handle_response(token, suggestions) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/AbcSize
      numbers = suggestions_options(suggestions)
      # :nocov:
      letter = stdin_getch("qaAsSrR?h\u0003\u0004#{numbers.join}")
      case letter
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
      when *numbers
        handle_replace_with_suggestion(token, suggestions, letter)
      when '?', 'h'
        handle_help(token, suggestions)
      end
    end

    def handle_replace_with_suggestion(token, suggestions, letter)
      replacement = suggestions[letter.to_i - 1]

      token.replace(replacement)
      increment(:total_fixed)
      puts "Replaced #{red(token)} with #{green(replacement)}"
      throw :check_file_from, token
    end

    def handle_skip(token)
      increment(:total_skipped)
      yield token if block_given?
      puts "Skipped #{red(token)}"
    end

    def handle_help(token, suggestions) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      clear_line(2)
      puts ''
      if suggestions.length > 1
        puts "#{key '1'}...#{key suggestions.length.to_s} "\
          "Replace #{red token} with the numbered suggestion"
      elsif suggestions.length == 1
        puts "#{key '1'} Replace #{red token} with the numbered suggestion"
      end
      puts "#{key 'a'} Add #{red token} to a word list"
      puts "#{key 'r'} Replace #{red token}"
      puts "#{key 'R'} Replace this and all future instances of #{red token}"
      puts "#{key 's'} Skip #{red token}"
      puts "#{key 'S'} Skip this and all future instances of #{red token}"
      puts "#{key 'h'} Show this help"
      puts "[ctrl] + #{key 'C'} Exit spellr"
      puts ''
      print "What do you want to do? [ ]\e[2D"
      handle_response(token, suggestions)
    end
  end
end

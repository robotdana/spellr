# frozen_string_literal: true

require 'io/console'
require_relative '../spellr'
require_relative 'interactive_add'
require_relative 'interactive_replacement'
require_relative 'base_reporter'

module Spellr
  class Interactive < BaseReporter
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

    def stdin_getch
      choice = output.stdin.getch
      clear_current_line
      choice
    end

    def prompt(token)
      print bold('[r,R,s,S,a,e,?]')

      handle_response(token)
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

    def clear_current_line
      print "\r\e[K"
    end

    def handle_response(token) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      case stdin_getch
      when "\u0003" # ctrl c
        exit 1
      when 'a'
        Spellr::InteractiveAdd.new(token, self)
      when 's', "\u0004" # ctrl d
        handle_skip(token)
      when 'S'
        handle_skip(token) { |skip_token| global_skips << skip_token.to_s }
      when 'R'
        Spellr::InteractiveReplacement.new(token, self).global_replace
      when 'r'
        Spellr::InteractiveReplacement.new(token, self).replace
      when 'e'
        Spellr::InteractiveReplacement.new(token, self).replace_line
      when '?'
        handle_help(token)
      else
        clear_current_line
        call(token)
      end
    end

    def handle_skip(token)
      increment(:total_skipped)
      yield token if block_given?
      puts "Skipped #{red(token)}"
    end

    def handle_help(token) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      puts "#{bold '[r]'} Replace #{red token}"
      puts "#{bold '[R]'} Replace all future instances of #{red token}"
      puts "#{bold '[s]'} Skip #{red token}"
      puts "#{bold '[S]'} Skip all future instances of #{red token}"
      puts "#{bold '[a]'} Add #{red token} to a word list"
      puts "#{bold '[e]'} Edit the whole line"
      puts "#{bold '[?]'} Show this help"
      handle_response(token)
    end
  end
end

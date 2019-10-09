# frozen_string_literal: true

require 'io/console'
require 'readline'
require_relative '../spellr'
require_relative 'reporter'
require_relative 'interactive_add'
require_relative 'interactive_replacement'
require_relative 'string_format'

module Spellr
  class Interactive
    include Spellr::StringFormat

    attr_reader :global_replacements, :global_skips
    attr_accessor :total_skipped
    attr_accessor :total_fixed
    attr_accessor :total_added

    def finish(checked) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      puts "\n"
      puts "#{pluralize 'file', checked} checked"
      puts "#{pluralize 'error', total} found"
      puts "#{pluralize 'error', total_skipped} skipped" if total_skipped.positive?
      puts "#{pluralize 'error', total_fixed} fixed" if total_fixed.positive?
      puts "#{pluralize 'word', total_added} added" if total_added.positive?
    end

    def total
      total_skipped + total_fixed + total_added
    end

    def initialize
      @global_replacements = {}
      @global_skips = []
      @total_skipped = 0
      @total_fixed = 0
      @total_added = 0
    end

    def call(token)
      return if attempt_global_replacement(token)
      return if attempt_global_skip(token)

      Spellr::Reporter.new.call(token)

      prompt(token)
    end

    def prompt(token)
      print bold('[r,R,s,S,a,e,?]')

      handle_response(token)
    rescue Interrupt
      puts '^C again to exit'
    end

    def attempt_global_skip(token)
      return unless global_skips.include?(token.to_s)

      puts "Automatically skipped #{red(token)}"
      self.total_skipped += 1
    end

    def attempt_global_replacement(token, replacement = global_replacements[token.to_s])
      return unless replacement

      token.replace(replacement)
      self.total_fixed += 1
      puts "Automatically replaced #{red(token)} with #{green(replacement)}"
      throw :check_file_from, token
    end

    def clear_current_line
      print "\r\e[K"
    end

    def stdin_getch
      choice = STDIN.getch
      clear_current_line
      choice
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
      self.total_skipped += 1
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

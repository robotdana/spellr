# frozen_string_literal: true

require 'io/console'
require 'readline'
require_relative '../spellr'
require_relative 'reporter'
require_relative 'string_format'

module Spellr
  class Interactive # rubocop:disable Metrics/ClassLength
    include Spellr::StringFormat

    attr_reader :global_replacements, :global_skips
    attr_reader :global_insensitive_replacements
    attr_reader :global_insensitive_skips
    attr_accessor :total_skipped
    attr_accessor :total_fixed
    attr_accessor :total_added

    def finish(checked) # rubocop:disable Metrics/AbcSize
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
      @global_insensitive_replacements = {}
      @global_skips = []
      @global_insensitive_skips = []
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
      print bold('[a,s,S,r,R,e,?]')

      handle_response(token)
    rescue Interrupt
      puts '^C again to exit'
    end

    def attempt_global_skip(token)
      return unless global_skips.include?(token.to_s) ||
        global_insensitive_skips.include?(token.normalize)

      self.total_skipped += 1
    end

    def attempt_global_replacement(token)
      global_replacement = global_replacements[token.to_s]
      global_replacement ||= global_insensitive_replacements[token.normalize]
      return unless global_replacement

      token.replace(global_replacement)
      self.total_fixed += 1
      raise Spellr::DidReplacement, token
    end

    def clear_current_line
      print "\r\e[K"
    end

    def handle_response(token) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      task = STDIN.getch
      clear_current_line

      case task
      when "\u0003" # ctrl c
        exit 1
      when 'a'
        handle_add(token)
      when 's', "\u0004" # ctrl d
        handle_skip(token)
      when 'S'
        handle_skip(token) { |skip_token| global_skips << skip_token.to_s }
      when 'i'
        handle_skip(token) { |skip_token| global_insensitive_skips << skip_token.downcase }
      when 'R'
        handle_replacement(token) { |replacement| global_replacements[token.to_s] = replacement }
      when 'I'
        handle_replacement(token) { |replacement| global_insensitive_replacements[token.normalize] = replacement }
      when 'r'
        handle_replacement(token)
      when 'e'
        handle_replace_line(token)
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
    end

    # TODO: handle more than 16 options
    def handle_add(token) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      puts "Add #{red(token)} to wordlist:"
      languages = Spellr.config.languages_for(token.location.file)

      languages.each do |wordlist|
        puts "[#{wordlist.key}] #{wordlist.name}"
      end
      choice = STDIN.getch
      clear_current_line
      case choice
      when "\u0003" # ctrl c
        puts '^C again to exit'
        call(token)
      when *languages.map(&:key)
        wl = languages.find { |w| w.key == choice }.project_wordlist

        wl.add(token)
        self.total_added += 1
        raise Spellr::DidAdd, token
      else
        handle_add(token)
      end
    end

    def handle_replacement(token, original_token: token) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      readline_editable_print(token.chomp)
      highlighted_token = token == original_token ? red(token) : token.highlight(original_token.char_range)
      puts "#{aqua '>>'} #{highlighted_token.chomp}"
      prompt = "#{aqua '=>'} "
      replacement = Readline.readline(prompt)
      if replacement.empty?
        call(token)
      else
        full_replacement = token == original_token ? replacement : replacement + "\n"
        token.replace(full_replacement)
        yield replacement if block_given?
        self.total_fixed += 1
        raise Spellr::DidReplacement, token
      end
    rescue Interrupt
      puts '^C again to exit'
      call(original_token)
    end

    def handle_replace_line(token)
      handle_replacement(
        token.line,
        original_token: token
      )
    end

    def handle_help(token) # rubocop:disable Metrics/AbcSize
      puts "#{bold '[r]'} Replace #{red token}"
      puts "#{bold '[R]'} Replace all future instances of #{red token}"
      puts "#{bold '[s]'} Skip #{red token}"
      puts "#{bold '[S]'} Skip all future instances of #{red token}"
      puts "#{bold '[a]'} Add #{red token} to a word list"
      puts "#{bold '[e]'} Edit the whole line"
      puts "#{bold '[?]'} Show this help"
      handle_response(token)
    end

    def readline_editable_print(string)
      Readline.pre_input_hook = lambda {
        Readline.refresh_line
        Readline.insert_text string.to_s
        Readline.redisplay

        # Remove the hook right away.
        Readline.pre_input_hook = nil
      }
    end
  end
end

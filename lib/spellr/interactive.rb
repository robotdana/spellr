# frozen_string_literal: true

require 'io/console'
require 'readline'
require_relative '../spellr'
require_relative 'reporter'
module Spellr
  class Interactive # rubocop:disable Metrics/ClassLength
    attr_reader :global_replacements, :global_skips
    attr_reader :global_insensitive_replacements
    attr_reader :global_insensitive_skips

    def finish(checked) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
      puts "\r"
      puts ''
      puts "#{checked} file#{'s' if checked != 1} checked"
      total = @total_skipped + @total_fixed + @total_added
      puts "#{total} error#{'s' if total != 1} found"
      puts "#{@total_skipped} error#{'s' if @total_skipped != 1} skipped" if @total_skipped.positive?
      puts "#{@total_fixed} error#{'s' if @total_fixed != 1} fixed" if @total_fixed.positive?
      puts "#{@total_added} word#{'s' if @total_added != 1} added" if @total_added.positive?
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
      print "\033[0;1m[a,s,S,i,r,R,I,?]\033[0m"

      handle_response(token)
    rescue Interrupt
      print "\r"
    end

    def attempt_global_skip(token)
      return unless global_skips.include?(token.to_s) ||
        global_insensitive_skips.include?(token.downcase)

      @total_skipped += 1
    end

    def attempt_global_replacement(token)
      global_replacement = global_replacements[token.to_s]
      global_replacement ||= global_insensitive_replacements[token.downcase]
      return unless global_replacement

      token.replace(global_replacement)
      @total_fixed += 1
      raise Spellr::DidReplacement
    end

    def handle_response(token) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      task = STDIN.getch
      print "\r"
      case task
      when "\u0003" # ctrl c
        puts "\r"
        exit 0
      when 'a'
        @total_added += 1
        handle_add(token)
        return
      when 's', "\u0004" # ctrl d
        @total_skipped += 1
        return
      when 'S'
        global_skips << token.to_s
        @total_skipped += 1
        return
      when 'i'
        global_insensitive_skips << token.downcase
        @total_skipped += 1
        return
      when 'R'
        handle_replacement(token) { |replacement| global_replacements[token.to_s] = replacement }
      when 'I'
        handle_replacement(token) { |replacement| global_insensitive_replacements[token.downcase] = replacement }
      when 'r'
        handle_replacement(token)
      when '?'
        handle_help(token)
      else
        call(token)
      end
    end

    # TODO: handle more than 10 options
    def handle_add(token)
      puts "Add \033[31m#{token}\033[0m to wordlist:"
      wordlists = Spellr.config.languages_for(token.file).flat_map(&:addable_wordlists)

      wordlists.each_with_index do |wordlist, i|
        puts "[#{i}] #{wordlist.name}"
      end
      wordlists[STDIN.getch.to_i].add(token)
    end

    def handle_replacement(token) # rubocop:disable Metrics/MethodLength
      readline_editable_print(token)
      replacement = Readline.readline("\033[31m#{token}\033[0m => ")
      if replacement.empty?
        call(token)
      else
        token.replace(replacement)
        yield replacement if block_given?
        @total_fixed += 1
        raise Spellr::DidReplacement
      end
    rescue Interrupt
      print "\r"
      call(token)
    end

    def handle_help(token)
      puts "\033[0;1m[r]\033[0;0m Replace \033[31m#{token}"
      puts "\033[0;1m[R]\033[0;0m Replace all future instances of \033[31m#{token}"
      puts "\033[0;1m[I]\033[0;0m Replace all future instances of \033[31m#{token}\033[0m case insensitively"
      puts "\033[0;1m[s]\033[0;0m Skip \033[31m#{token}"
      puts "\033[0;1m[S]\033[0;0m Skip all future instances of \033[31m#{token}"
      puts "\033[0;1m[i]\033[0;0m Skip all future instances of \033[31m#{token}\033[0m case insensitively"
      puts "\033[0;1m[a]\033[0;0m Add \033[31m#{token}\033[0m to a word list"
      puts "\033[0;1m[?]\033[0;0m Show this help"
      puts "\033[0m"
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

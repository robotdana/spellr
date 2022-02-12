# frozen_string_literal: true

require 'readline'
require_relative 'string_format'

module Spellr
  class InteractiveReplacement
    include Spellr::StringFormat

    attr_reader :token, :reporter, :token_highlight
    attr_accessor :global
    alias_method :global?, :global

    def initialize(token, reporter)
      @token = token
      @token_highlight = red(token)
      @reporter = reporter
      Readline.input = reporter.output.stdin
      Readline.output = reporter.output.stdout
    end

    def global_replace
      self.global = true
      replace
    end

    def complete_replacement(replacement)
      handle_global_replacement(replacement)
      token.replace(replacement)

      reporter.increment(:total_fixed)
      puts "\n\e[0mReplaced #{'all ' if global?}#{token_highlight} with #{green(replacement)}"
      throw :check_file_from, token
    end

    def handle_global_replacement(replacement)
      reporter.global_replacements[token.to_s] = replacement if global?
    end

    def ask_replacement
      puts ''
      puts "  #{lighten '[^C] to go back'}"
      prompt_replacement
    end

    def prompt_replacement
      Readline.pre_input_hook = -> { pre_input_hook(token) }
      prompt = "  Replace #{'all ' if global?}#{token_highlight} with: \e[32m"
      Readline.readline(prompt)
    rescue Interrupt
      handle_ctrl_c
    end

    def re_ask_replacement
      print "\e[0m\a\e[1T"

      try_replace(prompt_replacement)
    end

    def try_replace(replacement)
      return re_ask_replacement if replacement == token
      return re_ask_replacement if replacement.empty?

      complete_replacement(replacement)
    end

    def replace
      try_replace(ask_replacement)
    end

    def handle_ctrl_c
      print "\e[0m"
      reporter.clear_line(4)
      reporter.call(token, only_prompt: true)
    end

    private

    def pre_input_hook(value)
      Readline.refresh_line
      Readline.insert_text value.to_s
      Readline.redisplay

      # Remove the hook right away.
      Readline.pre_input_hook = nil
    end

    def puts(str)
      reporter.puts(str)
    end
  end
end

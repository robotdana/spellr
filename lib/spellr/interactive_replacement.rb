# frozen_string_literal: true

module Spellr
  class InteractiveReplacement
    include Spellr::StringFormat

    attr_reader :token, :reporter, :original_token, :token_highlight, :suffix

    def initialize(token, reporter)
      @original_token = token
      @token = token
      @token_highlight = red(token)
      @reporter = reporter
    end

    def global_replace
      replace { |replacement| reporter.global_replacements[token.to_s] = replacement }
    end

    def replace_line
      @token = token.line
      @token_highlight = token.highlight(original_token.char_range).chomp
      @suffix = "\n"

      replace
    end

    def complete_replacement(replacement)
      token.replace("#{replacement}#{suffix}")

      reporter.total_fixed += 1
      puts "Replaced #{red(token.chomp)} with #{green(replacement)}"
      throw :check_file_from, token
    end

    def replace # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      readline_editable_print(token.chomp)

      puts "#{aqua '>>'} #{token_highlight}"
      replacement = Readline.readline("#{aqua '=>'} ")

      return reporter.call(token) if replacement.empty?

      yield replacement if block_given?
      complete_replacement(replacement)
    rescue Interrupt
      puts '^C again to exit'
      reporter.call(original_token)
    end

    def readline_editable_print(string) # rubocop:disable Metrics/MethodLength
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

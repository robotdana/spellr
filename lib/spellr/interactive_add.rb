# frozen_string_literal: true

require_relative '../spellr'
require_relative 'string_format'

module Spellr
  class InteractiveAdd
    include Spellr::StringFormat

    attr_reader :token, :reporter

    def initialize(token, reporter)
      @token = token
      @reporter = reporter

      ask_wordlist
    end

    def languages
      @languages ||= Spellr.config.languages_for(token.location.file.to_path)
    end

    def addable_languages
      languages.select(&:addable?)
    end

    def language_keys
      @language_keys ||= addable_languages.map(&:key)
    end

    def ask_wordlist
      puts "Add #{red(token)} to wordlist:"

      addable_languages.each do |language|
        puts "[#{language.key}] #{language.name}"
      end

      handle_wordlist_choice(reporter.stdin_getch)
    end

    def handle_ctrl_c
      puts '^C again to exit'
      reporter.call(token)
    end

    def handle_wordlist_choice(choice) # rubocop:disable Metrics/MethodLength
      case choice
      when "\u0003"
        handle_ctrl_c
      when *language_keys
        add_to_wordlist(choice)
      else
        ask_wordlist
      end
    end

    def add_to_wordlist(choice)
      wordlist = addable_languages.find { |w| w.key == choice }.project_wordlist
      wordlist << token
      reporter.increment(:total_added)
      puts "Added #{red(token)} to #{wordlist.name} wordlist"
      throw :check_file_from, token
    end

    def puts(str)
      reporter.puts(str)
    end
  end
end

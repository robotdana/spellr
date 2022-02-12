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

      puts ''
      ask_wordlist
    end

    def languages
      @languages ||= Spellr.config.languages_for(token.location.file)
    end

    def addable_languages
      languages.select(&:addable?)
    end

    def language_keys
      @language_keys ||= addable_languages.map(&:key)
    end

    def ask_wordlist
      addable_languages.each { |l| puts "  #{key l.key} #{l.name}" }
      puts "  [^#{bold 'C'}] to go back"
      print "  Add #{red(token)} to which wordlist? "
      reporter.prompt_for_key

      handle_wordlist_choice
    end

    def handle_ctrl_c
      reporter.clear_line(language_keys.length + 5)
      reporter.call(token, only_prompt: true)
    end

    def handle_wordlist_choice
      choice = reporter.stdin_getch("#{language_keys.join}\u0003")
      # :nocov:
      case choice
      # :nocov:
      when "\u0003" then handle_ctrl_c
      when *language_keys then add_to_wordlist(choice)
      end
    end

    def add_to_wordlist(choice)
      wordlist = find_wordlist(choice)
      wordlist << token
      reporter.increment(:total_added)
      puts "\nAdded #{red(token)} to the #{bold wordlist.name} wordlist"
      throw :check_file_from, token
    end

    def find_wordlist(key)
      addable_languages.find { |w| w.key == key }.project_wordlist
    end

    def puts(str)
      reporter.puts(str)
    end
  end
end

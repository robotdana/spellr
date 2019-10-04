# frozen_string_literal: true

require_relative '../spellr'
require_relative 'config_loader'
require_relative 'language'
require_relative 'reporter'
require 'pathname'

module Spellr
  class Config
    attr_writer :reporter
    attr_reader :config_file
    attr_accessor :quiet
    alias_method :quiet?, :quiet

    def initialize
      @config = ConfigLoader.new
    end

    def valid?
      only_has_one_key_per_language
      keys_are_single_characters
      errors.empty?
    end

    def print_errors
      if $stderr.tty?
        errors.each { |e| warn "\e[31m#{e}\e[0m" }
      else
        errors.each { |e| warn e }
      end
    end

    def errors
      @errors ||= []
    end

    def word_minimum_length
      @word_minimum_length ||= @config[:word_minimum_length]
    end

    def only
      @config[:only] || []
    end

    def ignored
      @config[:ignore]
    end

    def color
      @config[:color]
    end

    def clear_cache
      remove_instance_variable(:@wordlists) if defined?(@wordlists)
      remove_instance_variable(:@languages) if defined?(@languages)
      remove_instance_variable(:@errors) if defined?(@errors)
      remove_instance_variable(:@word_minimum_length) if defined?(@word_minimum_length)
    end

    def languages
      @languages ||= @config[:languages].map do |key, args|
        Spellr::Language.new(key, args)
      end
    end

    def pwd
      @pwd ||= Pathname.pwd
    end

    def languages_for(file)
      languages.select { |l| l.matches?(file) }
    end

    def wordlists
      @wordlists ||= languages.flat_map(&:wordlists)
    end

    def wordlists_for(file)
      languages_for(file).flat_map(&:wordlists)
    end

    def config_file=(value)
      ::File.read(value) # raise Errno::ENOENT if the file doesn't exist
      @config = ConfigLoader.new(value)
    end

    def reporter
      @reporter ||= default_reporter
    end

    private

    def only_has_one_key_per_language
      conflicting_languages = languages
        .group_by(&:key)
        .values.select { |g| g.length > 1 }

      return if conflicting_languages.empty?

      conflicting_languages.each do |conflicts|
        errors << "Error: #{conflicts.map(&:name).join(' & ')} share the same language key (#{conflicts.first.key}). "\
          'Please define one to be different with `key:`'
      end
    end

    def keys_are_single_characters
      bad_languages = languages.select { |l| l.key.length > 1 }
      return if bad_languages.empty?

      bad_languages.each do |language|
        errors << "Error: #{language.name} defines a key that is too long (#{language.key}). "\
          'Please change it to be a single character'
      end
    end

    def default_reporter
      Spellr::Reporter.new
    end
  end
end

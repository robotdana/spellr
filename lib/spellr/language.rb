# frozen_string_literal: true

require_relative 'wordlist'

module Spellr
  class Language
    attr_reader :name
    attr_reader :key

    def initialize(name, # rubocop:disable Metrics/ParameterLists, Metrics/MethodLength
      key: name[0],
      generate: nil,
      only: [],
      includes: [],
      description: '',
      hashbangs: [],
      locale: [])
      unless only.empty?
        warn <<~WARNING
          \e[33mSpellr: `only:` language yaml key with a list of fnmatch rules is deprecated.
          Please use `includes:` instead, which uses gitignore-inspired rules.
          see github.com/robotdana/fast_ignore#using-an-includes-list for details\e[0m
        WARNING
      end

      if generate
        warn <<~WARNING
          \e[33mSpellr: `generate:` and generation is now deprecated. Choose the language
          using the key `locale:` (any of US,AU,CA,GB,GBz,GBs as a string or array).\e[0m
        WARNING
      end

      @name = name
      @key = key
      @description = description
      @includes = only + includes
      @hashbangs = hashbangs
      @locales = Array(locale)
    end

    def matches?(file)
      return true if @includes.empty?

      return true if fast_ignore.allowed?(file.to_s)

      file = Spellr::File.wrap(file)
      return true if !@hashbangs.empty? && file.hashbang && @hashbangs.any? { |h| file.hashbang.include?(h) }
    end

    def fast_ignore
      @fast_ignore ||= FastIgnore.new(include_rules: @includes, gitignore: false)
    end

    def wordlists
      default_wordlists.select(&:exist?)
    end

    def gem_wordlist
      @gem_wordlist ||= Spellr::Wordlist.new(
        Pathname.new(__dir__).parent.parent.join('wordlists', "#{name}.txt")
      )
    end

    def project_wordlist
      @project_wordlist ||= Spellr::Wordlist.new(
        Pathname.pwd.join('.spellr_wordlists', "#{name}.txt"),
        name: name
      )
    end

    def locale_wordlists
      @locale_wordlists ||= @locales.map do |locale|
        Spellr::Wordlist.new(
          Pathname.new(__dir__).parent.parent.join('wordlists', name.to_s, "#{locale}.txt")
        )
      end
    end

    private

    def load_wordlists(name, paths)
      wordlists = paths + default_wordlist_paths(name)

      wordlists.map(&Spellr::Wordlist.method(:new))
    end

    def default_wordlists
      [
        gem_wordlist,
        project_wordlist,
        *locale_wordlists
      ]
    end
  end
end

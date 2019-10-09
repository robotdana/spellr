# frozen_string_literal: true

require_relative 'wordlist'

module Spellr
  class Language
    attr_reader :name
    attr_reader :key

    def initialize(name, key: name[0], includes: [], hashbangs: [], locale: [])
      @name = name
      @key = key
      @includes = includes
      @hashbangs = hashbangs
      @locales = Array(locale)
    end

    def matches?(file)
      matches_includes?(file) || matches_hashbangs?(file)
    end

    def wordlists
      default_wordlists.select(&:exist?)
    end

    def project_wordlist
      @project_wordlist ||= Spellr::Wordlist.new(
        Pathname.pwd.join('.spellr_wordlists', "#{name}.txt"),
        name: name
      )
    end

    private

    def matches_hashbangs?(file)
      return @includes.empty? if @hashbangs.empty?

      file = Spellr::File.wrap(file)
      return unless file.hashbang

      @hashbangs.any? { |h| file.hashbang.include?(h) }
    end

    def matches_includes?(file)
      return @hashbangs.empty? if @includes.empty?

      @fast_ignore ||= FastIgnore.new(include_rules: @includes, gitignore: false)
      @fast_ignore.allowed?(file.to_s)
    end

    def gem_wordlist
      @gem_wordlist ||= Spellr::Wordlist.new(
        Pathname.new(__dir__).parent.parent.join('wordlists', "#{name}.txt")
      )
    end

    def locale_wordlists
      @locale_wordlists ||= @locales.map do |locale|
        Spellr::Wordlist.new(
          Pathname.new(__dir__).parent.parent.join('wordlists', name.to_s, "#{locale}.txt")
        )
      end
    end

    def load_wordlists(name, paths)
      wordlists = paths + default_wordlist_paths(name)

      wordlists.map(&Spellr::Wordlist.method(:new))
    end

    def default_wordlists
      [
        gem_wordlist,
        *locale_wordlists,
        project_wordlist
      ]
    end
  end
end

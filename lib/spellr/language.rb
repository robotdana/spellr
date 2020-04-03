# frozen_string_literal: true

require_relative 'wordlist'
require_relative 'file'
require 'pathname'
require 'fast_ignore'

module Spellr
  class Language
    attr_reader :name
    attr_reader :key

    def initialize(name, key: name[0], includes: [], hashbangs: [], locale: [], addable: true) # rubocop:disable Metrics/ParameterLists, Metrics/MethodLength
      @name = name
      @key = key
      @includes = includes
      @hashbangs = hashbangs
      @locales = Array(locale)
      @addable = addable
    end

    def addable?
      @addable
    end

    def matches?(file)
      matches_includes?(file) || matches_hashbangs?(file)
    end

    def wordlists
      default_wordlists.select(&:exist?)
    end

    def project_wordlist
      @project_wordlist ||= Spellr::Wordlist.new(
        Spellr.config.pwd.join('.spellr_wordlists', "#{name}.txt"),
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

      @fast_ignore ||= FastIgnore.new(
        include_rules: @includes, gitignore: false, root: Spellr.config.pwd_s
      )
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

    def default_wordlists
      [
        gem_wordlist,
        *locale_wordlists,
        project_wordlist
      ]
    end
  end
end

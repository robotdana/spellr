# frozen_string_literal: true

require_relative 'wordlist'
require_relative 'file'
require 'pathname'
require 'fast_ignore'

module Spellr
  class Language
    attr_reader :name
    attr_reader :key

    def initialize(name, key: name[0], includes: [], hashbangs: [], locale: [], addable: true) # rubocop:disable Metrics/ParameterLists
      @name = name
      @key = key
      @includes = includes + hashbangs.map { |h| "#!:#{h}" }
      @locales = Array(locale)
      @addable = addable
    end

    def addable?
      @addable
    end

    def wordlists
      default_wordlists.select(&:exist?)
    end

    def project_wordlist
      @project_wordlist ||= Spellr::Wordlist.new(
        Spellr.pwd.join('.spellr_wordlists', "#{name}.txt"),
        name: name
      )
    end

    def matches?(file)
      return true if @includes.empty?

      fast_ignore.allowed?(file.to_s, directory: false, content: file.first_line)
    end

    private

    def fast_ignore
      @fast_ignore ||= FastIgnore.new(
        include_rules: @includes, gitignore: false, root: Spellr.pwd_s
      )
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

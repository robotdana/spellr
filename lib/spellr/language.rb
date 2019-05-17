# frozen_string_literal: true

require_relative 'wordlist'

module Spellr
  class Language
    attr_reader :wordlists

    def initialize(name,
      wordlists: [],
      generate: nil,
      only: [],
      hashbangs: [])
      @name = name
      @wordlists = load_wordlists(name, wordlists, generate)
      @only = only
      @hashbangs = hashbangs
    end

    def matches?(file)
      return true if @only.empty?
      return true if @only.any? { |o| file.fnmatch?(o) }
      return true if file.hashbang && @hashbangs.any? { |h| file.hashbang.include?(h) }
    end

    private

    def load_wordlists(name, paths, generate)
      wordlists = paths + default_wordlist_paths(name)

      if wordlists.empty? && generate
        require_relative 'cli'
        require 'shellwords'
        warn "Generating wordlist for #{name}"

        Spellr::CLI.new(generate.shellsplit)

        wordlists = paths + default_wordlist_paths(name)
      end

      wordlists.map { |w| Spellr::Wordlist.new(w) }
    end

    def default_wordlist_paths(name)
      [
        Pathname.new(__dir__).parent.parent.join('wordlists', "#{name}.txt"),
        Pathname.pwd.join('.spellr_wordlists', 'generated', "#{name}.txt"),
        Pathname.pwd.join('.spellr_wordlists', "#{name}.txt"),
        Pathname.new("~/.spellr_wordlists/generated/#{name}.txt").expand_path,
        Pathname.new("~/.spellr_wordlists/#{name}.txt").expand_path
      ].select(&:exist?)
    end
  end
end

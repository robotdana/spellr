# frozen_string_literal: true

require_relative 'wordlist'

module Spellr
  class Language
    attr_reader :wordlists

    def initialize(name,
      wordlists: ["$GEM/#{name}"],
      only: [],
      hashbangs: [])
      @name = name
      @wordlists = wordlists.map { |w| Spellr::Wordlist.new(w) }
      @only = only
      @hashbangs = hashbangs
    end

    def matches?(file)
      return true if @only.empty?
      return true if @only.any? { |o| file.fnmatch?(o) }
      return true if file.hashbang && @hashbangs.any? { |h| file.hashbang.include?(h) }
    end
  end
end

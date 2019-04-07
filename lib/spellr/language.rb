# frozen_string_literal: true

module Spellr
  class Language
    def initialize(name,
      wordlists: ["$GEM/#{name}"],
      extensions: :all,
      filenames: [],
      hashbangs: [])
      @name = name
      @wordlists = wordlists.map { |w| Spellr::Wordlist.new(w) }
      @extensions = extensions
      @filenames = filenames
      @hashbangs = hashbangs
    end

    def matches?(file)
      return true if @extensions == :all
      return true if @extensions.include?(file.extname)
      return true if @filenames.include?(file.basename)
      return true if file.hashbang && @hashbangs.any? { |h| file.hashbang.include?(h) }
    end
  end
end

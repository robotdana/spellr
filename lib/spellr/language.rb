# frozen_string_literal: true

require_relative 'wordlist'

module Spellr
  class Language
    attr_reader :name
    attr_reader :key

    def initialize(name, # rubocop:disable Metrics/ParameterLists
      key: name[0],
      generate: nil,
      only: [],
      description: '',
      hashbangs: [])
      @name = name
      @key = key
      @description = description
      @generate = generate
      @only = only
      @hashbangs = hashbangs
    end

    def matches?(file)
      return true if @only.empty?

      file = Spellr::File.wrap(file)
      return true if @only.any? { |o| file.fnmatch?(o) }
      return true if file.hashbang && @hashbangs.any? { |h| file.hashbang.include?(h) }
    end

    def wordlists
      generate_wordlist unless generated_project_wordlist.exist?
      default_wordlists.select(&:exist?)
    end

    def generate_wordlist
      return [] unless generate

      require_relative 'cli'
      require 'shellwords'
      warn "Generating wordlist for #{name}"

      Spellr::CLI.new(generate.shellsplit)

      default_wordlists
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

    def generated_project_wordlist
      @generated_project_wordlist ||= Spellr::Wordlist.new(
        Pathname.pwd.join('.spellr_wordlists', 'generated', "#{name}.txt")
      )
    end

    private

    attr_reader :generate

    def load_wordlists(name, paths, _generate)
      wordlists = paths + default_wordlist_paths(name)

      wordlists.map(&Spellr::Wordlist.method(:new))
    end

    def default_wordlists
      [
        gem_wordlist,
        generated_project_wordlist,
        project_wordlist
      ]
    end
  end
end

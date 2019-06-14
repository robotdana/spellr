# frozen_string_literal: true

require_relative 'wordlist'

module Spellr
  class Language
    attr_reader :name

    def initialize(name, # rubocop:disable Metrics/ParameterLists
      wordlists: [],
      generate: nil,
      only: [],
      description: '',
      hashbangs: [])
      @name = name
      @description = description
      @generate = generate
      @wordlist_paths = wordlists
      @only = only
      @hashbangs = hashbangs
    end

    def matches?(file)
      return true if @only.empty?
      return true if @only.any? { |o| file.fnmatch?(o) }
      return true if file.hashbang && @hashbangs.any? { |h| file.hashbang.include?(h) }
    end

    def config_wordlists
      @config_wordlists ||= @wordlist_paths.map(&Spellr::Wordlist.method(:new))
    end

    def wordlists
      w = config_wordlists + default_wordlists
      return generate_wordlist if w.empty?

      w
    end

    def generate_wordlist
      return [] unless generate

      require_relative 'cli'
      require 'shellwords'
      warn "Generating wordlist for #{name}"

      Spellr::CLI.new(generate.shellsplit)

      config_wordlists + default_wordlists
    end

    def addable_wordlists
      ((config_wordlists - default_wordlists) + [project_wordlist, global_wordlist]).uniq(&:path)
    end

    def gem_wordlist
      @gem_wordlist ||= Spellr::Wordlist.new(
        Pathname.new(__dir__).parent.parent.join('wordlists', "#{name}.txt")
      )
    end

    def project_wordlist
      @project_wordlist ||= Spellr::Wordlist.new(
        Pathname.pwd.join('.spellr_wordlists', "#{name}.txt"),
        name: "#{name} (project)"
      )
    end

    def generated_project_wordlist
      @generated_project_wordlist ||= Spellr::Wordlist.new(
        Pathname.pwd.join('.spellr_wordlists', 'generated', "#{name}.txt")
      )
    end

    def generated_global_wordlist
      @generated_global_wordlist ||= Spellr::Wordlist.new(
        Pathname.new("~/.spellr_wordlists/generated/#{name}.txt").expand_path
      )
    end

    def global_wordlist
      @global_wordlist ||= Spellr::Wordlist.new(
        Pathname.new("~/.spellr_wordlists/#{name}.txt").expand_path,
        name: "#{name} (global)"
      )
    end

    private

    attr_reader :generate

    def load_wordlists(name, paths, _generate)
      wordlists = paths + default_wordlist_paths(name)

      wordlists.map(&Spellr::Wordlist.method(:new))
    end

    def custom_addable_wordlists(wordlists)
      default_paths = default_wordlist_paths
      wordlists.map { |w| Spellr::Wordlist.new(w) }.reject { |w| default_paths.include?(w.path) }
    end

    def default_wordlists
      [
        gem_wordlist,
        global_wordlist,
        generated_global_wordlist,
        generated_project_wordlist,
        project_wordlist
      ].select(&:exist?)
    end
  end
end

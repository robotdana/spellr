# frozen_string_literal: true

require 'yaml'

module Spellr
  class Config
    def initialize
      default_config = load_yaml(__dir__, '..', '.spellr.yml')
      project_config = load_yaml(Dir.pwd, '.spellr.yml')

      @config = merge_config(default_config, project_config)
    end

    def reporter
      Spellr::Reporter
    end

    def word_minimum_length
      @config[:word_minimum_length]
    end

    def only
      @config[:only] || []
    end

    def ignored
      @config[:ignore]
    end

    def languages
      @languages ||= @config[:languages].map do |key, args|
        [key, Spellr::Language.new(key, args)]
      end.to_h
    end

    def wordlists
      @wordlists ||= languages.values.flat_map(&:wordlists)
    end

    def wordlists_for(file)
      languages.values.flat_map do |l|
        next [] unless l.matches?(file)

        l.wordlists
      end
    end

    private

    def load_yaml(*path)
      file = ::File.join(*path)
      return {} unless ::File.exist?(file)

      YAML.safe_load(::File.read(file), symbolize_names: true)
    end

    def merge_config(default, project)
      if project.is_a?(Array) && default.is_a?(Array)
        default | project
      elsif project.is_a?(Hash) && default.is_a?(Hash)
        default.merge(project) { |_k, d, p| merge_config(d, p) }
      else
        project
      end
    end
  end
end

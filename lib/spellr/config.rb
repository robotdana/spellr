# frozen_string_literal: true

require_relative '../spellr'

module Spellr
  class Config
    attr_writer :reporter
    attr_reader :config_file
    attr_accessor :quiet
    alias_method :quiet?, :quiet

    def initialize
      @config_file = ::File.join(Dir.pwd, '.spellr.yml')
      load_config
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
      require_relative 'language'

      @languages ||= @config[:languages].map do |key, args|
        [key, Spellr::Language.new(key, args)]
      end.to_h
    end

    def languages_for(file)
      languages.values.select { |l| l.matches?(file) }
    end

    def wordlists
      @wordlists ||= languages.values.flat_map(&:wordlists)
    end

    def wordlists_for(file)
      languages_for(file).flat_map(&:wordlists)
    end

    def config_file=(value)
      ::File.read(value) # raise Errno::ENOENT if the file doesn't exist
      @config_file = value
      load_config
    end

    def reporter
      @reporter ||= default_reporter
    end

    private

    def default_reporter
      require_relative 'reporter'

      Spellr::Reporter.new
    end

    def load_config
      default_config = load_yaml(::File.join(__dir__, '..', '.spellr.yml'))
      project_config = load_yaml(config_file)

      @config = merge_config(default_config, project_config)
    end

    def load_yaml(path)
      require 'yaml'

      return {} unless ::File.exist?(path)

      YAML.safe_load(::File.read(path), symbolize_names: true)
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

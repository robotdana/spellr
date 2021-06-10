# frozen_string_literal: true

require 'yaml'
require_relative 'backports'

module Spellr
  class ConfigLoader
    # :nocov:
    using ::Spellr::YAMLSymbolizeNames if defined?(::Spellr::YAMLSymbolizeNames)
    # :nocov:

    attr_reader :config_file

    def initialize(config_file = ::File.join(Spellr.pwd, '.spellr.yml'))
      @config_file = config_file
    end

    def [](value)
      load_config unless defined?(@config)
      @config[value]
    end

    private

    def load_config
      default_config = load_yaml(::File.join(__dir__, '..', '.spellr.yml'))
      project_config = load_yaml(config_file)

      @config = merge_config(default_config, project_config)
    end

    def load_yaml(path)
      return {} unless ::File.exist?(path)

      YAML.safe_load(::File.read(path, encoding: ::Encoding::UTF_8), symbolize_names: true)
    end

    def merge_config(default, project) # rubocop:disable Metrics/MethodLength
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

# frozen_string_literal: true

require 'yaml'

module Spellr
  class ConfigLoader
    attr_reader :config_file

    def initialize(config_file = ::File.join(Dir.pwd, '.spellr.yml'))
      @config_file = config_file
    end

    def config_file=(value)
      # TODO: nicer error message
      ::File.read(value) # raise Errno::ENOENT if the file doesn't exist
      @config_file = value
      @config = nil
    end

    def [](value)
      load_config unless @config
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

      symbolize_yaml_safe_load(path)
    end

    def symbolize_yaml_safe_load(path)
      if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.5')
        YAML.safe_load(::File.read(path), symbolize_names: true)
      else
        symbolize_names!(YAML.safe_load(::File.read(path)))
      end
    end

    def symbolize_names!(obj) # rubocop:disable Metrics/MethodLength
      case obj
      when Hash
        obj.keys.each do |key|
          obj[key.to_sym] = symbolize_names!(obj.delete(key))
        end
      when Array
        obj.map! { |ea| symbolize_names!(ea) }
      end
      obj
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

# frozen_string_literal: true

require_relative 'validations'
require 'timeout'
require 'io/console'

module Spellr
  class ConfigValidator
    include Spellr::Validations

    validate :not_interactive_and_parallel
    validate :interactive_is_interactive
    validate :only_has_one_key_per_language
    validate :languages_with_conflicting_keys
    validate :keys_are_single_characters

    def valid?
      raise ::Spellr::Config::Invalid, errors.join("\n") unless super
    end

    def interactive_is_interactive # rubocop:disable Metrics/MethodLength
      return unless Spellr.config.reporter.class.name == 'Spellr::Interactive'

      # I have no idea how to check for this other than call it
      Timeout.timeout(0.0000000000001) do
        Spellr.config.output.stdin.getch
      end
    rescue Errno::ENOTTY, Errno::ENODEV, IOError
      errors << 'CLI error: --interactive is unavailable in a non-interactive terminal'
    rescue Timeout::Error
      nil
    end

    def not_interactive_and_parallel
      return unless Spellr.config.reporter.class.name == 'Spellr::Interactive' &&
        Spellr.config.parallel

      errors << 'CLI error: --interactive is incompatible with --parallel'
    end

    def only_has_one_key_per_language
      languages_with_conflicting_keys.each do |conflicts|
        errors << "Config error: #{conflicts.map(&:name).join(' & ')} share the same language key "\
        "(#{conflicts.first.key}). Please define one to be different with `key:`"
      end
    end

    def languages_with_conflicting_keys
      Spellr.config.languages.select(&:addable?).group_by(&:key).values.select do |g|
        g.length > 1
      end
    end

    def keys_are_single_characters
      bad_languages = Spellr.config.languages.select { |l| l.key.length > 1 }

      bad_languages.each do |lang|
        errors << "Config error: #{lang.name} defines a key that is too long (#{lang.key}). "\
          'Please change it to be a single character'
      end
    end
  end
end

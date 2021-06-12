# frozen_string_literal: true

require_relative 'validations'
require 'timeout'
require 'io/console'

module Spellr
  class ConfigValidator
    include Spellr::Validations

    validate :checker_and_reporter_coexist
    validate :interactive_is_interactive
    validate :only_has_one_key_per_language
    validate :languages_with_conflicting_keys
    validate :keys_are_single_characters
    validate :prune_wordlists_with_no_argv_patterns
    validate :prune_wordlists_with_no_dry_run

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

    def checker_and_reporter_coexist
      return unless Spellr.config.reporter.class.name == 'Spellr::Interactive' &&
        Spellr.config.checker.name == 'Spellr::CheckParallel'

      errors << 'CLI error: --interactive is incompatible with --parallel'
    end

    def only_has_one_key_per_language
      languages_with_conflicting_keys.each do |conflicts|
        errors << "Config error: #{conflicts.map(&:name).join(' & ')} share the same language key "\
        "(#{conflicts.first.key}). Please define one to be different with `key:`"
      end
    end

    def prune_wordlists_with_no_argv_patterns
      return unless Spellr.config.prune_wordlists? && !Spellr.config.file_list_patterns.empty?

      errors << 'CLI error: --prune-wordlists is incompatible with file patterns'
    end

    def prune_wordlists_with_no_dry_run
      return unless Spellr.config.prune_wordlists? && Spellr.config.dry_run?

      errors << 'CLI error: --prune-wordlists is incompatible with --dry-run'
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

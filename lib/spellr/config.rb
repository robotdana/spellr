# frozen_string_literal: true

require_relative '../spellr'
require_relative 'config_loader'
require_relative 'language'
require_relative 'config_validator'
require_relative 'output'

require 'pathname'

module Spellr
  class Config
    attr_writer :reporter
    attr_writer :checker
    attr_reader :config_file
    attr_accessor :dry_run
    alias_method :dry_run?, :dry_run

    def initialize
      @config = ConfigLoader.new
    end

    def word_minimum_length
      @word_minimum_length ||= @config[:word_minimum_length]
    end

    def key_heuristic_weight
      @key_heuristic_weight ||= @config[:key_heuristic_weight]
    end

    def key_minimum_length
      @key_minimum_length ||= @config[:key_minimum_length]
    end

    def includes
      @includes ||= @config[:includes] || []
    end

    def excludes
      @excludes ||= @config[:excludes] || []
    end

    def languages
      @languages ||= @config[:languages].map do |key, args|
        Spellr::Language.new(key, **args)
      end
    end

    def languages_for(file)
      languages.select { |l| l.matches?(file) }
    end

    def wordlists_for(file)
      languages_for(file).flat_map(&:wordlists)
    end

    def config_file=(value)
      reset!
      @config = ConfigLoader.new(value)
    end

    def output
      @output ||= Spellr::Output.new
    end

    def reporter
      @reporter ||= default_reporter
    end

    def checker
      return dry_run_checker if dry_run?

      @checker ||= default_checker
    end

    def valid?
      Spellr::ConfigValidator.new.valid?
    end

    def reset! # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
      @config = ConfigLoader.new
      remove_instance_variable(:@languages) if defined?(@languages)
      remove_instance_variable(:@excludes) if defined?(@excludes)
      remove_instance_variable(:@includes) if defined?(@includes)
      remove_instance_variable(:@word_minimum_length) if defined?(@word_minimum_length)
      remove_instance_variable(:@key_heuristic_weight) if defined?(@key_heuristic_weight)
      remove_instance_variable(:@key_minimum_length) if defined?(@key_minimum_length)
    end

    private

    def dry_run_checker
      require_relative 'check_dry_run'
      Spellr::CheckDryRun
    end

    def default_reporter
      require_relative 'reporter'
      Spellr::Reporter.new
    end

    def default_checker
      require_relative 'check_parallel'
      Spellr::CheckParallel
    end
  end
end

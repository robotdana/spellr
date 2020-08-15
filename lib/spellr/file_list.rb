# frozen_string_literal: true

require 'fast_ignore'
require_relative '../spellr'
require_relative 'file'

module Spellr
  class FileList
    include Enumerable

    def initialize(patterns = nil)
      @patterns = patterns
    end

    def each
      return enum_for(:each) unless block_given?

      fast_ignore.each do |file|
        yield(Spellr::File.new(file))
      end
    end

    def to_a
      enum_for(:each).to_a
    end

    private

    def configured_rules
      return { gitignore: false } if Spellr.config.suppress_file_rules

      {
        ignore_rules: Spellr.config.excludes,
        include_rules: Spellr.config.includes
      }
    end

    def fast_ignore # rubocop:disable Metrics/MethodLength
      FastIgnore.new(
        **configured_rules,
        argv_rules: @patterns,
        follow_symlinks: true,
        root: Spellr.pwd_s
      )
    end
  end
end

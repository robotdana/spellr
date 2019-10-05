# frozen_string_literal: true

require 'fast_ignore'
require_relative '../spellr'
require_relative 'file'

module Spellr
  class FileList
    include Enumerable

    def initialize(*patterns)
      @patterns = patterns
    end

    # anchored patterns are significantly faster on large codebases
    def cli_patterns
      @patterns.map do |pattern|
        if pattern.match?(%r{^([/~*]|\.{1,2}/)})
          pattern
        else
          "/#{pattern}"
        end
      end
    end

    def each
      gitignore = ::File.join(Dir.pwd, '.gitignore')
      gitignore = nil unless ::File.exist?(gitignore)

      FastIgnore.new(
        ignore_rules: Spellr.config.excludes,
        include_rules: Spellr.config.includes + cli_patterns,
        gitignore: gitignore
      ).each do |file|
        file = Spellr::File.new(file)

        yield(file)
      end
    end

    def to_a
      enum_for(:each).to_a
    end
  end
end

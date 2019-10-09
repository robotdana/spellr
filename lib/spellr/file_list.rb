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

    def each
      fast_ignore.each do |file|
        file = Spellr::File.new(file)

        yield(file)
      end
    end

    def to_a
      enum_for(:each).to_a
    end

    private

    # anchored patterns are significantly faster on large codebases
    def cli_patterns
      @patterns.map do |pattern|
        pattern.sub(%r{^(?!(?:[/~*]|\.{1,2}/))}, '/')
      end
    end

    def gitignore_path
      gitignore = ::File.join(Dir.pwd, '.gitignore')
      gitignore if ::File.exist?(gitignore)
    end

    def fast_ignore
      FastIgnore.new(
        ignore_rules: Spellr.config.excludes,
        include_rules: Spellr.config.includes + cli_patterns,
        gitignore: gitignore_path
      )
    end
  end
end

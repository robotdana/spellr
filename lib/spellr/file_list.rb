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

    def config_only?(file)
      Spellr.config.only.empty? || Spellr.config.only.any? { |o| file.fnmatch?(o) }
    end

    def cli_only?(file)
      @patterns.empty? || @patterns.any? { |p| file.fnmatch?(p) }
    end

    def each
      # TODO: handle no gitignore
      gitignore = ::File.join(Dir.pwd, '.gitignore')
      gitignore = nil unless ::File.exist?(gitignore)
      FastIgnore.new(rules: Spellr.config.ignored, gitignore: gitignore).each do |file|
        file = Spellr::File.new(file)
        next unless cli_only?(file)
        next unless config_only?(file)

        yield(file)
      end
    end

    def to_a
      enum_for(:each).to_a
    end
  end
end

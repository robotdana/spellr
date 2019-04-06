# frozen_string_literal: true

require 'pathname'
require 'fast_ignore'
module Spellr
  class FileList
    attr_accessor :globs
    include Enumerable

    def dictionary?(file)
      @dictionaries ||= Spellr.config.dictionaries.map { |_k, v| v.file.to_s }.sort

      @dictionaries.bsearch { |value| file <=> value }
    end

    def each
      FastIgnore.new(rules: Spellr.config.exclusions).each do |file|
        next if dictionary?(file)

        file = Spellr::File.new(file)
        yield(file)
      end
    end

    def to_a
      enum_for(:each).to_a
    end
  end
end

# frozen_string_literal: true

require 'pathname'

module Spellr
  class File
    attr_reader :file

    def initialize(name)
      @file = Pathname.new(name).expand_path
    end

    def dictionaries # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      @dictionaries ||= Spellr.config.dictionaries.values.select do |dict|
        (dict.extensions.empty? && dict.filenames.empty? && dict.hashbangs.empty?) ||
          dict.extensions.include?(file.extname.delete_prefix('.')) ||
          dict.filenames.include?(file.basename) ||
          (hashbang && dict.hashbangs.any? { |match| hashbang.include?(match) })
      end
    end

    def hashbang
      return if file.extname != ''
      return unless first_line.start_with?('#!')

      first_line
    end

    def read
      file.read
    end

    def each_line
      file.each_line
    end

    def first_line
      @first_line ||= each_line.first
    end

    def lines
      file.read.lines
    end

    def to_s
      file.to_s
    end

    def ==(other)
      return to_s == other if other.respond_to?(:to_str)

      super
    end

    def each_token(&block)
      Spellr::Tokenizer.new(file.read).each(&block)
    end
  end
end

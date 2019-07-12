# frozen_string_literal: true

module Spellr
  class LineLocation
    attr_reader :file
    attr_reader :line_number
    attr_reader :char_offset
    attr_reader :byte_offset

    def initialize(file = '[String]', line_number = 1, char_offset: 0, byte_offset: 0)
      @file = file
      @line_number = line_number
      @char_offset = char_offset
      @byte_offset = byte_offset
    end

    def to_s
      "#{relative_file_name}:#{line_number}"
    end

    def file_name
      file.respond_to?(:to_path) ? file.to_path : file
    end

    def relative_file_name
      Pathname.new(file_name).relative_path_from(Pathname.pwd)
    end
  end
end

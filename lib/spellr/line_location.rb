# frozen_string_literal: true

require_relative 'file'

module Spellr
  class LineLocation
    attr_reader :line_number
    attr_reader :char_offset
    attr_reader :byte_offset

    def initialize(file = '[String]', line_number = 1, char_offset: 0, byte_offset: 0)
      @filename = file
      @line_number = line_number
      @char_offset = char_offset
      @byte_offset = byte_offset
    end

    def to_s
      "#{file_relative_path}:#{line_number}"
    end

    def file_relative_path
      file.relative_path
    end

    def file
      @file ||= Spellr::File.wrap(@filename)
    end

    def advance(line)
      LineLocation.new(@filename,
                       line_number + 1,
                       char_offset: char_offset + line.length,
                       byte_offset: byte_offset + line.bytesize)
    end
  end
end

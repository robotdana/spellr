# frozen_string_literal: true

require_relative 'line_location'

module Spellr
  class ColumnLocation
    attr_reader :char_offset
    attr_reader :byte_offset
    attr_accessor :line_location

    def initialize(char_offset: 0, byte_offset: 0, line_location: LineLocation.new)
      @line_location = line_location
      @char_offset = char_offset
      @byte_offset = byte_offset
    end

    def absolute_char_offset
      char_offset + line_location.char_offset
    end

    def absolute_byte_offset
      byte_offset + line_location.byte_offset
    end

    def line_number
      line_location.line_number
    end

    def file
      line_location.file
    end

    def to_s
      "#{line_location}:#{char_offset}"
    end

    # :nocov:
    def inspect
      "#<#{self.class.name} #{self}>"
    end
    # :nocov:

    def coordinates
      [line_number, char_offset]
    end
  end
end

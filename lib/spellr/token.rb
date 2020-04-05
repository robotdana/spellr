# frozen_string_literal: true

require_relative 'column_location'
require_relative 'string_format'

class String
  @@spellr_normalize = {} # rubocop:disable Style/ClassVars # I want to share this with subclasses

  def spellr_normalize
    @@spellr_normalize.fetch(to_s) do |term|
      @@spellr_normalize[term] = "#{term.strip.downcase.unicode_normalize.tr('’', "'")}\n"
    end
  end
end

module Spellr
  class Token < String
    attr_reader :location, :line, :replacement

    def initialize(string, line: string, location: ColumnLocation.new)
      @location = location
      @line = line
      super(string)
    end

    def line=(new_line)
      @line = new_line
      location.line_location = new_line.location.line_location
    end

    # :nocov:
    def inspect
      "#<#{self.class.name} #{to_s.inspect} @#{location}>"
    end
    # :nocov:

    def char_range
      @char_range ||=
        location.char_offset...(location.char_offset + length)
    end

    def byte_range # leftovers:allow i don't want to delete this
      @byte_range ||=
        location.byte_offset...(location.byte_offset + bytesize)
    end

    def file_char_range
      @file_char_range ||=
        location.absolute_char_offset...(location.absolute_char_offset + length)
    end

    def file_byte_range # leftovers:allow i don't want to delete this
      @file_byte_range ||=
        location.absolute_byte_offset...(location.absolute_byte_offset + bytesize)
    end

    def coordinates
      location.coordinates
    end

    def highlight(range = char_range)
      "#{slice(0...(range.first))}#{Spellr::StringFormat.red slice(range)}#{slice(range.last..-1)}"
    end

    def replace(replacement)
      @replacement = replacement
      location.file.insert(replacement, file_char_range)
    end
  end
end

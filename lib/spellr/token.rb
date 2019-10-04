# frozen_string_literal: true

# frozen string_literal: true

require_relative 'column_location'
require_relative 'string_format'

class String
  def normalize
    normalize_cache[to_s]
  end

  def normalize_cache
    @@normalize_cache ||= Hash.new do |cache, term| # rubocop:disable Style/ClassVars # i want this shared with subclasses
      cache[term] = term.strip.downcase.unicode_normalize.tr('’', "'") + "\n"
    end
  end

  alias_method :match?, :match unless RUBY_VERSION >= '2.4'
end

module Spellr
  class Token < String
    attr_reader :location, :line, :replacement

    def self.wrap(value)
      return value if value.is_a?(Spellr::Token)

      Spellr::Token.new(value || '')
    end

    def initialize(string, line: string, location: ColumnLocation.new)
      @location = location
      @line = line
      super(string)
    end

    def strip
      @strip ||= begin
        lstripped = lstrip
        new_column_location = lstripped_column_location(lstripped)
        Token.new(lstripped.rstrip, line: line, location: new_column_location)
      end
    end

    def lstripped_column_location(lstripped)
      ColumnLocation.new(
        byte_offset: bytesize - lstripped.bytesize,
        char_offset: length - lstripped.length,
        line_location: location.line_location
      )
    end

    def inspect
      "#<#{self.class.name} #{to_s.inspect} @#{location}>"
    end

    def char_range
      @char_range ||= location.char_offset...(location.char_offset + length)
    end

    def byte_range
      @byte_range ||= location.byte_offset...(location.byte_offset + bytesize)
    end

    def coordinates
      location.coordinates
    end

    def highlight(range = char_range)
      "#{slice(0...(range.first))}#{Spellr::StringFormat.red slice(range)}#{slice(range.last..-1)}"
    end

    def replace(replacement)
      @replacement = replacement
      ::File.open(file_name, 'r+') do |f|
        body = f.read
        body[location.absolute_char_offset...(location.absolute_char_offset + length)] = replacement
        f.rewind
        f.truncate(0)
        f.write(body)
      end
    end

    def file_name
      location.file_name
    end
  end
end

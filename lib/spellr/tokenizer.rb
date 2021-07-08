# frozen_string_literal: true

require_relative 'token'
require_relative 'column_location'
require_relative 'line_location'
require_relative 'line_tokenizer'

module Spellr
  class Tokenizer
    attr_reader :file, :filename

    def initialize(file, start_at: nil, skip_key: true)
      @filename = file
      @start_at = start_at || ColumnLocation.new(line_location: LineLocation.new(file))
      @file = file.is_a?(StringIO) || file.is_a?(IO) ? file : ::File.new(file)
      @file.pos = @start_at.line_location.byte_offset

      @line_tokenizer = LineTokenizer.new('', skip_key: skip_key)
    end

    def terms # leftovers:test
      enum_for(:each_term).to_a
    end

    def map(&block)
      enum_for(:each_token).map(&block)
    end

    def each_term(&block)
      file.each_line do |line|
        prepare_tokenizer_for_line(line)&.each_term(&block)
      end
    ensure
      file.close
    end

    def each_token(skip_if_included: nil) # rubocop:disable Metrics/MethodLength
      each_line_with_stats do |line, line_number, char_offset, byte_offset|
        prepare_tokenizer_for_line(line)&.each_token(skip_if_included: skip_if_included) do |token|
          token.line = prepare_line(line, line_number, char_offset, byte_offset)

          yield token
        end
      end
    end

    def prepare_line(line, line_number, char_offset, byte_offset)
      line_location = LineLocation.new(
        filename, line_number, char_offset: char_offset, byte_offset: byte_offset
      )
      column_location = ColumnLocation.new(line_location: line_location)
      Token.new(line, location: column_location)
    end

    def each_line_with_stats # rubocop:disable Metrics/MethodLength
      char_offset = @start_at.line_location.char_offset
      byte_offset = @start_at.line_location.byte_offset

      file.each_line.with_index(@start_at.line_location.line_number) do |line, line_number|
        yield line, line_number, char_offset, byte_offset

        char_offset += line.length
        byte_offset += line.bytesize
      end
    ensure
      file.close
    end

    def normalized_terms
      enum_for(:each_term).map(&:spellr_normalize).uniq.sort
    end

    private

    attr_reader :line_tokenizer

    def prepare_tokenizer_for_line(line)
      return if line.match?(Spellr::TokenRegexps::SPELLR_LINE_DISABLE_RE)

      line_tokenizer.string = line
      line_tokenizer.pos = 0
      line_tokenizer
    end
  end
end

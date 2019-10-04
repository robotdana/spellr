# frozen_string_literal: true

require_relative '../spellr'
require_relative 'token'
require_relative 'column_location'
require_relative 'line_location'
require_relative 'line_tokenizer'

module Spellr
  class Tokenizer
    attr_reader :file
    attr_reader :start_at

    attr_accessor :disabled
    alias_method :disabled?, :disabled

    def initialize(file, start_at: nil, skip_uri: true, skip_key: true)
      # $stderr.puts start_at if start_at
      @start_at = start_at || ColumnLocation.new(line_location: LineLocation.new(file))
      @file = file.is_a?(StringIO) || file.is_a?(IO) ? file : ::File.new(file)
      @file.pos = @start_at.line_location.byte_offset

      @line_tokenizer = LineTokenizer.new(skip_uri: skip_uri, skip_key: skip_key)
    end

    def terms
      enum_for(:each_term).to_a
    end

    def map(&block)
      enum_for(:each_token).map(&block)
    end

    def each_term(&block)
      each_line_with_offset do |line, line_number|
        prepare_tokenizer_for_line(line, line_number).each_term(&block)
      end
    end

    def each_token(&block) # rubocop:disable Metrics/AbcSize
      char_offset = @start_at.line_location.char_offset
      byte_offset = @start_at.line_location.byte_offset

      each_line_with_offset do |line, line_number|
        line_location = LineLocation.new(file, line_number, byte_offset: byte_offset, char_offset: char_offset)
        char_offset += line.length
        byte_offset += line.bytesize
        line = Token.new(line, location: ColumnLocation.new(line_location: line_location))
        prepare_tokenizer_for_line(line, line_number).each_token(&block)
      end
    end

    def normalized_terms
      enum_for(:each_term).map(&:normalize).uniq.sort
    end

    private

    attr_reader :line_tokenizer

    def each_line_with_offset(&block)
      file.each_line.with_index(@start_at.line_number, &block)
    end

    def prepare_tokenizer_for_line(line, _line_number)
      line_tokenizer.string = line
      line_tokenizer.pos = 0
      line_tokenizer
    end
  end
end

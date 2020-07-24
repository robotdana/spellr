# frozen_string_literal: true

require_relative 'file'

module Spellr
  class LineLocation
    attr_reader :line_number, :char_offset, :byte_offset, :file

    def initialize(
      file = ::Spellr::File.new('[string]'),
      line_number = 1,
      char_offset: 0,
      byte_offset: 0
    )
      @file = file
      @line_number = line_number
      @char_offset = char_offset
      @byte_offset = byte_offset
    end

    def to_s
      "#{file.relative_path}:#{line_number}"
    end
  end
end

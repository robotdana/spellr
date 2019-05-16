# frozen_string_literal: true

module Spellr
  class Token
    attr_reader :string, :file, :start_pos, :line_number, :line_start_pos

    def initialize(string, file: nil, loc: [])
      @string = string
      @file = file
      @start_pos = loc[0]
      @line_number = loc[1]
      @line_start_pos = loc[2]
    end

    def length
      string.length
    end

    def to_s
      string
    end

    def downcase
      to_s.downcase
    end

    def inspect
      "#<#{self.class.name}:#{string}>"
    end

    def column
      start_pos - line_start_pos
    end

    def column_end
      column + length
    end

    def coordinates
      [line_number, column]
    end

    def line
      @line ||= file.each_line.to_a[line_number - 1]
    end

    def before
      @before ||= line.slice(0...column)
    end

    def after
      @after ||= line.slice(column_end..-1)
    end

    def replace(replacement)
      string = file.read
      string[start_pos...(start_pos + length)] = replacement
      file.write(string)
    end
  end
end

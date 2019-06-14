# frozen_string_literal: true

module Spellr
  class Token
    attr_reader :string, :file, :start_pos, :line_number, :line_start_pos

    def self.normalize(string)
      string.downcase.unicode_normalize.tr('’', "'") + "\n"
    end

    def initialize(string, file: nil, loc: [])
      @string = string
      @file = file
      @start_pos = loc[0]
      @line_number = loc[1]
      @line_start_pos = loc[2]
    end

    def loc
      [start_pos, line_number, line_start_pos]
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

    def normalize
      self.class.normalize(to_s)
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

    def line_token
      indent = line.length - line.lstrip.length
      Token.new(line.strip,
        file: file,
        loc: [
          line_start_pos + indent,
          line_number,
          line_start_pos
        ])
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

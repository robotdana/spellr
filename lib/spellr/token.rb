# frozen_string_literal: true

module Spellr
  class Token
    attr_reader :string, :file_start, :file

    def initialize(string, start:, file:)
      @string = string
      @file_start = start
      @file = file
    end

    def line
      @line ||= file.each_line.to_a[line_number - 1]
    end

    def line_number
      @line_number ||= file_before.each_line.count
    end

    def length
      string.length
    end

    def file_before
      @file_before ||= file.read.slice(0...file_start)
    end

    def file_end
      @file_end ||= file_start + length
    end

    def file_after
      @file_after ||= file.read.slice(file_end..-1)
    end

    def line_start
      @line_start ||= file_before.each_line.to_a.last.length
    end

    def to_s
      string
    end

    def inspect
      "#<Spellr::Token #{string} offset=#{file_start}>"
    end

    def line_end
      @line_end ||= line_start + length
    end

    def line_before
      @line_before ||= line.slice(0...line_start)
    end

    def line_after
      @line_after ||= line.slice(line_end..-1)
    end
  end
end

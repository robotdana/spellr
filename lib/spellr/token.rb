# frozen_string_literal: true

module Spellr
  class Token
    attr_reader :string, :start, :file, :line_number, :line

    def initialize(string, start: nil, file: nil, line_number: nil, line: nil)
      @string = string
      @start = start
      @line_number = line_number
      @line = line
      @file = file
    end

    def length
      string.length
    end

    def to_s
      string
    end

    def inspect
      "#<Spellr::Token #{string}>"
    end

    def end
      start + length
    end

    def before
      @before ||= line.slice(0...start)
    end

    def after
      @after ||= line.slice(self.end..-1)
    end
  end
end

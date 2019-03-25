# frozen_string_literal: true

module Spellr
  class Line
    attr_reader :line, :file, :line_number

    def initialize(line, file: nil, line_number: nil)
      @line = line
      @file = file
      @line_number = line_number
    end

    def each_token(&block)
      Spellr::Token.each_token(self, &block)
    end

    def scan(pattern, &block)
      line.scan(pattern, &block)
    end

    def slice(*args)
      line.slice(*args)
    end

    def to_s
      line
    end
  end
end

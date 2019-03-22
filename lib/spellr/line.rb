module Spellr
  class Line
    attr_reader :line, :file, :line_number

    def initialize(line, file: nil, line_number: nil)
      @line = line
      @file = file
      @line_number = line_number
    end

    def each_token(&block)
      Spellr::Token.tokenize(self).each(&block)
    end

    def location
      [file, line_number].join(':')
    end

    def scan(pattern, &block)
      line.scan(pattern, &block)
    end

    def slice(*args)
      line.slice(*args)
    end
  end
end

# frozen_string_literal: true

require 'strscan'

class TTYString
  def initialize(input_string, ignore_color: false)
    @scanner = StringScanner.new(input_string)
    @output = []
    @ignore_color = ignore_color
    @cursor = [0, 0]
  end

  def to_s
    render
    output.map { |c| Array(c).map { |x| x || ' ' }.join.rstrip }.join("\n")
  end

  def render # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/LineLength
    until scanner.eos?
      if scanner.peek(1) == "\b" # can't use scan because /\b/ matches everything.
        backspace(*cursor)
        scanner.pos += 1
      elsif scanner.scan(/\n/)
        cursor[0] += 1
        cursor[1] = 0
        output[cursor.first] ||= []
      elsif scanner.scan(/\r/)
        cursor[1] = 0
      elsif scanner.scan(/\t/)
        append_output(' ' * 7)
      elsif scanner.scan(/\e\[\d*(;\d+)*m/)
        append_output(scanner.matched) unless ignore_color
      elsif scanner.scan(/[^\e\r\n\t\b]+/)
        append_output(scanner.matched)
      elsif scanner.scan(/\e\[K/)
        delete_line_from_cursor(*cursor)
      elsif scanner.scan(/\e\[\d+A/)
        count = scanner.matched.match(/\e\[(\d+)A/)[1]
        cursor[0] -= count.to_i
      else
        raise "unrecognized character beginning #{scanner.rest}"
      end
    end
  end

  private

  attr_reader :output
  attr_reader :cursor
  attr_reader :scanner
  attr_reader :ignore_color

  def delete_line_from_cursor(row, col)
    output[row] ||= []
    output[row].slice!(col, output[row].length)
  end

  def backspace(row, col)
    output[row] ||= []
    output[row].slice!([col - 1, 0].max)
    cursor[1] -= 1 if cursor[1] > 0
  end

  def append_output(string)
    string.each_char do |char|
      set_output(*cursor, char)
      cursor[1] += 1
    end
  end

  def set_output(row, col, char)
    output[row] ||= []
    output[row][col] = char
  end
end

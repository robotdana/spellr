# frozen_string_literal: true

module Spellr
  class Reporter
    def initialize
      @total = 0
    end

    def finish(checked)
      puts "\n"
      puts "#{checked} file#{'s' if checked != 1} checked"
      puts "#{@total} error#{'s' if @total != 1} found"
    end

    AQUA = "\033[36m"
    RESET = "\033[0m"

    def call(token)
      puts "#{AQUA}#{token.location}#{RESET} #{token.line.highlight(token.char_range)}"

      @total += 1
    end
  end
end

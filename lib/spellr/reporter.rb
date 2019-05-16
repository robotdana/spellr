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
    RED = "\033[1;31m"
    RESET = "\033[0m"

    def call(token)
      location = "#{token.file}:#{token.line_number}:#{token.column}"
      line = "#{token.before}#{RED}#{token}#{RESET}#{token.after}".strip

      puts "#{AQUA}#{location}#{RESET} #{line}"

      @total += 1
    end
  end
end

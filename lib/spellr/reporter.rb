# frozen_string_literal: true

module Spellr
  module Reporter
    module_function

    AQUA = "\033[36m"
    RED = "\033[1;31m"
    RESET = "\033[0m"

    def call(token, startpos, line, line_number, file)
      before = line.slice(0...startpos)
      endpos = startpos + token.length
      after = line.slice(endpos..-1)

      location = "#{file}:#{line_number}:#{startpos}"
      line = "#{before}#{RED}#{token}#{RESET}#{after}".strip

      puts "#{AQUA}#{location}#{RESET} #{line}"
    end
  end
end

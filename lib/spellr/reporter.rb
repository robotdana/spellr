# frozen_string_literal: true

module Spellr
  module Reporter
    module_function

    AQUA = "\033[36m"
    RED = "\033[1;31m"
    RESET = "\033[0m"

    def call(token)
      # return

      location = "#{token.file}:#{token.line_number}:#{token.start}"
      line = "#{token.before}#{RED}#{token}#{RESET}#{token.after}".strip

      puts "#{AQUA}#{location}#{RESET} #{line}"
    end
  end
end

module Spellr
  module Reporter
    module_function
    AQUA = "\033[36m"
    RED = "\033[1;31m"
    RESET = "\033[0m"

    def call(token)
      line = "#{token.before}#{RED}#{token}#{RESET}#{token.after}".strip
      puts "#{AQUA}#{token.location}#{RESET} #{line}"
    end
  end
end

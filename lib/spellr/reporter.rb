module Spellr
  module Reporter
    module_function

    def report(token)
      puts "\033[36m#{token.line.file}:#{token.line.line_number}\033[0m "\
           "#{token.line.line.slice(0...token.start).lstrip}\033[1;31m#{token}\033[0m#{token.line.line.slice(token.end..-1)}"
    end

  end
end

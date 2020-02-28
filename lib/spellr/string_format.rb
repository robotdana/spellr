# frozen_string_literal: true

module Spellr
  module StringFormat
    module_function

    def pluralize(word, count)
      "#{count} #{word}#{'s' if count != 1}"
    end

    def aqua(text)
      "\e[36m#{text}#{normal}"
    end

    def normal(text = '')
      "\e[0m#{text}"
    end

    def bold(text)
      "\e[1;39m#{text}#{normal}"
    end

    def red(text)
      "\e[1;31m#{text}#{normal}"
    end

    def green(text)
      "\e[1;32m#{text}#{normal}"
    end
  end
end

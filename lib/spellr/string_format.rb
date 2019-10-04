# frozen_string_literal: true

require_relative 'config'

module Spellr
  module StringFormat
    module_function

    def pluralize(word, count)
      "#{count} #{word}#{'s' if count != 1}"
    end

    # TODO: make it work without color
    def color_enabled?
      true
    end

    def aqua(text)
      return text unless Spellr::StringFormat.color_enabled?

      "\e[36m#{text}#{normal}"
    end

    def normal(text = '')
      return text unless Spellr::StringFormat.color_enabled?

      "\e[0m#{text}"
    end

    def bold(text)
      return text unless Spellr::StringFormat.color_enabled?

      "\e[1;39m#{text}#{normal}"
    end

    def red(text)
      return text unless Spellr::StringFormat.color_enabled?

      "\e[1;31m#{text}#{normal}"
    end

    def green(text)
      return text unless Spellr::StringFormat.color_enabled?

      "\e[1;32m#{text}#{normal}"
    end
  end
end

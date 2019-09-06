# frozen_string_literal: true

require_relative 'string_format'

module Spellr
  class Reporter
    include Spellr::StringFormat

    attr_accessor :total

    def initialize
      @total = 0
    end

    def finish(checked)
      puts "\n"
      puts "#{pluralize 'file', checked} checked"
      puts "#{pluralize 'error', total} found"
    end

    def call(token)
      puts "#{aqua token.location} #{token.line.highlight(token.char_range).strip}"

      self.total += 1
    end
  end
end

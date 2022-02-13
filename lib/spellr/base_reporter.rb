# frozen_string_literal: true

require_relative 'string_format'
require_relative 'output'

module Spellr
  class BaseReporter
    include Spellr::StringFormat

    def initialize(output = nil)
      @output = output
    end

    def finish
      nil
    end

    def call(token)
      puts "#{aqua token.location} #{token.line.highlight(token.char_range).strip}"
    end

    def increment(counter)
      output.increment(counter)
    end

    def puts(str)
      output.puts(str)
    end

    def print(str)
      output.print(str)
    end

    def warn(str)
      output.warn(str)
    end

    def exit_code
      output.exit_code
    end

    def output
      @output ||= Spellr.config.output
    end

    def counts
      output.counts
    end

    def print_count(stat, noun, verb = stat, hide_zero: false)
      print_value(counts[stat], noun, verb, hide_zero: hide_zero)
    end

    def print_value(value, noun, verb, hide_zero: false)
      puts "#{pluralize noun, value} #{verb}" if !hide_zero || value.positive?
    end
  end
end

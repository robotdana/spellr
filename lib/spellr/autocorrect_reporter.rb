# frozen_string_literal: true

require_relative '../spellr'
require_relative 'base_reporter'
require_relative 'maybe_suggester'

module Spellr
  class AutocorrectReporter < BaseReporter
    def finish
      puts "\n"
      print_count(:checked, 'file')
      print_value(total, 'error', 'found')
      print_count(:total_fixed, 'error', 'fixed', hide_zero: true)
      print_count(:total_unfixed, 'error', 'unfixed', hide_zero: true)
    end

    def call(token)
      super

      handle_replace(token)
    end

    private

    def total
      counts[:total_unfixed] + counts[:total_fixed]
    end

    def handle_replace(token)
      replacement = ::Spellr::Suggester.suggestions(token).first
      return increment(:total_unfixed) unless replacement

      token.replace(replacement)
      increment(:total_fixed)
      puts "Replaced #{red(token)} with #{green(replacement)}"
      throw :check_file_from, token
    end
  end
end

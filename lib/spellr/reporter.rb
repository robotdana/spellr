# frozen_string_literal: true

require_relative 'base_reporter'

module Spellr
  class Reporter < Spellr::BaseReporter
    def finish
      puts "\n"
      puts "#{pluralize 'file', counts[:checked]} checked"
      puts "#{pluralize 'error', counts[:total]} found"
    end

    def call(token)
      super

      increment(:total)
    end
  end
end

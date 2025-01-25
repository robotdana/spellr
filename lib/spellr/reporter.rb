# frozen_string_literal: true

require_relative 'base_reporter'
require 'shellwords'
require 'set'

module Spellr
  class Reporter < Spellr::BaseReporter
    def finish
      warn "\n"
      print_count(:checked, 'file')
      print_count(:total, 'error', 'found')

      interactive_command if counts[:total].positive?
    end

    def call(token)
      super

      filenames << token.location.file.relative_path.to_s
      increment(:total)
    end

    private

    def interactive_command
      warn "\nto add or replace words interactively, run:"
      command = ['spellr', '--interactive']
      # sort is purely for repeatability for tests. so
      command.concat(counts[:filenames].to_a.sort) unless counts[:filenames].length > 20

      warn "  #{Shellwords.join(command)}"
    end

    def filenames
      output.counts[:filenames] = Set.new unless output.counts.key?(:filenames)
      output.counts[:filenames]
    end
  end
end

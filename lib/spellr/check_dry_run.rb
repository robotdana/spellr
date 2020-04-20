# frozen_string_literal: true

require_relative '../spellr'
require_relative 'check'

module Spellr
  class CheckDryRun < Check
    def check
      files.each do |file|
        @reporter.puts file.relative_path
      end
    end
  end
end

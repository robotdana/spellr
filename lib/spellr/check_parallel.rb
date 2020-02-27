# frozen_string_literal: true

require_relative '../spellr'
require_relative 'check'
require_relative 'output_stubbed'
require 'parallel'

module Spellr
  class CheckParallel < Check
    def check # rubocop:disable Metrics/MethodLength
      acc_reporter = @reporter
      Parallel.each(files, finish: ->(_, _, result) { acc_reporter.output << result }) do |file|
        @reporter = acc_reporter.class.new(Spellr::OutputStubbed.new)
        check_and_count_file(file)
        reporter.output
      end
      @reporter = acc_reporter

      reporter.finish
    end
  end
end

# frozen_string_literal: true

require_relative 'base_reporter'

module Spellr
  class QuietReporter < Spellr::BaseReporter
    def output
      @output ||= Spellr::OutputStubbed.new
    end

    def call(_token); end
  end
end

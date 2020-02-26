# frozen_string_literal: true

require_relative 'spellr/backports'
require_relative 'spellr/config'

module Spellr
  class Error < StandardError; end

  class Wordlist
    class NotFound < Spellr::Error; end
  end

  class InvalidByteSequence < ArgumentError
    RE = /invalid byte sequence/.freeze
    def self.===(error)
      error.is_a?(ArgumentError) && error.message.match?(RE)
    end
  end

  module_function

  def config
    @config ||= Spellr::Config.new
  end
end

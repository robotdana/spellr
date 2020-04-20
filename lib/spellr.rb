# frozen_string_literal: true

require_relative 'spellr/backports'
require_relative 'spellr/config'
require_relative 'spellr/pwd'

module Spellr
  class Error < StandardError; end

  class Wordlist
    class NotFound < Spellr::Error; end
  end

  class Config
    class NotFound < Spellr::Error; end
    class Invalid < Spellr::Error; end
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

  def exit(status = 0)
    throw(:spellr_exit, status)
  end
end

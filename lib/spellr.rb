# frozen_string_literal: true

module Spellr
  class Error < StandardError; end
  class DidReplacement < Spellr::Error
    attr_reader :token

    def initialize(token = nil)
      @token = token
    end
  end
  class DidAdd < Spellr::Error; end

  module_function

  def config
    require_relative 'spellr/config'
    @config ||= Spellr::Config.new
  end
end

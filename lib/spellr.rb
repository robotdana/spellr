# frozen_string_literal: true

module Spellr
  class Error < StandardError; end
  class DidReplacement < Spellr::Error; end

  module_function

  def config
    require_relative 'spellr/config'
    @config ||= Spellr::Config.new
  end
end

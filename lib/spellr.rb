# frozen_string_literal: true

module Spellr
  class Error < StandardError; end
  module_function

  def config
    require_relative 'spellr/config'
    @config ||= Spellr::Config.new
  end
end

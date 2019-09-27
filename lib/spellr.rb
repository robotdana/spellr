# frozen_string_literal: true

require_relative 'spellr/config'

module Spellr
  class Error < StandardError; end
  class Wordlist
    class NotFound < Spellr::Error; end
  end

  module_function

  def config
    @config ||= Spellr::Config.new
  end
end

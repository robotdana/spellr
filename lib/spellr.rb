# frozen_string_literal: true

require_relative 'spellr/version'
require_relative 'spellr/token'
require_relative 'spellr/line'
require_relative 'spellr/file_list'
require_relative 'spellr/file'
require_relative 'spellr/dictionary'
require_relative 'spellr/config'
require_relative 'spellr/reporter'
require_relative 'spellr/check'

module Spellr
  class Error < StandardError; end

  module_function

  def config
    @config ||= Spellr::Config.new
  end

  def configure
    yield(config)
  end
end

# frozen_string_literal: true

module Spellr
  class Error < StandardError; end

  require_relative 'spellr/version'
  require_relative 'spellr/tokenizer'
  require_relative 'spellr/token'
  require_relative 'spellr/file_list'
  require_relative 'spellr/file'
  require_relative 'spellr/scowl_downloader'
  require_relative 'spellr/language'
  require_relative 'spellr/wordlist'
  require_relative 'spellr/config'
  require_relative 'spellr/reporter'
  require_relative 'spellr/check'

  module_function

  def config
    @config ||= Spellr::Config.new
  end
end

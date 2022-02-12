# frozen_string_literal: true

require 'bundler/setup'
require_relative '../../lib/spellr/pwd'
require_relative '../../lib/spellr/suggester'

module Spellr
  module_function

  def pwd
    Pathname.new(ENV['SPELLR_TEST_PWD'])
  end

  def pwd_s
    ENV['SPELLR_TEST_PWD']
  end

  class Suggester
    class << self
      undef slow?

      def slow?
        false
      end
    end
  end
end

if ENV['SPELLR_SIMPLECOV']
  require 'simplecov'
  SimpleCov.command_name "CLI #{Process.pid}"
  SimpleCov.start
end

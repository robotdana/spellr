# frozen_string_literal: true

require 'simplecov'

SimpleCov.command_name "CLI #{Process.pid} #{ENV['SPELLR_TEST_DESCRIPTION']} #{rand}"
SimpleCov.start

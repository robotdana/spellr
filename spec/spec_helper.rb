# frozen_string_literal: true

require 'fileutils'
require 'pathname'
FileUtils.rm_rf(File.join(__dir__, '..', 'coverage'))

require 'simplecov'
SimpleCov.print_error_status = true
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.5')
  SimpleCov.minimum_coverage line: 100, branch: 100
else
  SimpleCov.minimum_coverage 100
end
SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
SimpleCov.start

require 'bundler/setup'
require 'webmock/rspec'
require 'spellr'
require 'pry'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
    c.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |c|
    c.verify_partial_doubles = true
  end

  config.example_status_persistence_file_path = '.rspec_status'
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.warnings = true
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  config.before do
    Spellr.config.reset!
  end

  require_relative './support/cli_helper'
  require_relative './support/stub_helper'
end

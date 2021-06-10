# frozen_string_literal: true

require 'fileutils'
require 'pathname'
FileUtils.rm_rf(File.join(__dir__, '..', 'coverage'))

# There were intermittent issues on travis with 2.5 that i don't understand.
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.6')
  require 'simplecov'
  require 'simplecov-console'

  SimpleCov.print_error_status = true
  SimpleCov.minimum_coverage line: 100, branch: 100

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console
  ])

  SimpleCov.start
end

require 'bundler/setup'
require 'webmock/rspec'
require 'spellr'
require 'pry'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
    c.include_chain_clauses_in_custom_matcher_descriptions = true
    c.max_formatted_output_length = 2000
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

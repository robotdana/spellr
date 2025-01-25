#!/usr/bin/env ruby
# frozen_string_literal: true

SimpleCov.print_error_status = false
SimpleCov.enable_coverage(:branch) if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.5')
SimpleCov.root __dir__
SimpleCov.formatter SimpleCov::Formatter::SimpleFormatter
SimpleCov.minimum_coverage 0
SimpleCov.add_filter '/backports'
SimpleCov.add_filter '/spec/'
# because i have to skip and mock some of it for expediency reasons
SimpleCov.add_filter '/bin/generate'
SimpleCov.enable_for_subprocesses true
SimpleCov.at_fork do |pid|
  # This needs a unique name so it won't be overwritten
  SimpleCov.command_name "#{SimpleCov.command_name} (subprocess: #{pid})"
  # be quiet, the parent process will be in charge of output and checking coverage totals
  SimpleCov.print_error_status = false
  SimpleCov.formatter SimpleCov::Formatter::SimpleFormatter
  SimpleCov.minimum_coverage 0
  # start
  SimpleCov.start
end
SimpleCov.start

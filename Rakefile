# frozen_string_literal: true

require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'leftovers/rake_task'

require_relative 'lib/spellr/rake_task'

RuboCop::RakeTask.new
RSpec::Core::RakeTask.new(:spec)
Spellr::RakeTask.generate_task
Leftovers::RakeTask.generate_task

task default: [:spec, :rubocop, :spellr, :leftovers, :build]

Rake::Task[:release].clear
desc "Create tag #{Bundler::GemHelper.instance.send(:version_tag)} and push"
task :release, [:remote] => [:"release:guard_clean", :"release:source_control_push"] do
end

task :keydata do
  require_relative 'lib/spellr/key_tuner/naive_bayes'
  FileUtils.rm NaiveBayes::YAML_PATH if File.exist?(NaiveBayes::YAML_PATH)
  NaiveBayes.new.save_to_yaml
end

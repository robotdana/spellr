# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require_relative 'lib/spellr/rake_task'

RSpec::Core::RakeTask.new(:spec)
Spellr::RakeTask.generate_task

task default: [:spec, :spellr]

task :keydata do
  require_relative 'lib/spellr/key_tuner/naive_bayes'
  FileUtils.rm NaiveBayes::YAML_PATH if File.exist?(NaiveBayes::YAML_PATH)
  NaiveBayes.new.save_to_yaml
end

# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/spellr'

RSpec.describe Spellr::Config do
  describe '#config_file=' do
    around do |example|
      with_temp_dir(example)
    end

    it "reloads the config even if you've already asked it something" do
      stub_fs_file 'my-spellr.yml', <<~YML
        word_minimum_length: 2
      YML

      expect(Spellr.config.word_minimum_length).to be 3
      Spellr.config.config_file = "#{Dir.pwd}/my-spellr.yml"
      expect(Spellr.config.word_minimum_length).to be 2
    end

    it "reloads the config even if you've asked it nothing" do
      stub_fs_file 'my-spellr.yml', <<~YML
        word_minimum_length: 2
      YML

      Spellr.config.config_file = "#{Dir.pwd}/my-spellr.yml"
      expect(Spellr.config.word_minimum_length).to be 2
    end

    it "reloads the config even if you've already asked it everything that could be cached" do
      stub_fs_file 'my-spellr.yml', <<~YML
        ---
        word_minimum_length: 2
        key_heuristic_weight: 1
        key_minimum_length: 21

        includes:
          - '*.*'
        excludes:
          - '*.rb'
        languages:
          french: {}
      YML

      expect(Spellr.config.word_minimum_length).to be 3
      expect(Spellr.config.key_heuristic_weight).to be 5
      expect(Spellr.config.key_minimum_length).to be 6
      expect(Spellr.config.languages.map(&:name)).not_to include(:french)
      expect(Spellr.config.includes).not_to include('*.*')
      expect(Spellr.config.excludes).not_to include('*.rb')

      Spellr.config.config_file = "#{Dir.pwd}/my-spellr.yml"

      expect(Spellr.config.word_minimum_length).to be 2
      expect(Spellr.config.key_heuristic_weight).to be 1
      expect(Spellr.config.key_minimum_length).to be 21
      expect(Spellr.config.languages.map(&:name)).to include(:french)
      expect(Spellr.config.includes).to include('*.*')
      expect(Spellr.config.excludes).to include('*.rb')
    end
  end
end

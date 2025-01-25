# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/spellr/null_suggester'
require_relative '../lib/spellr/token'
require_relative '../lib/spellr/tokenizer'

RSpec.describe Spellr::NullSuggester do
  before { with_temp_dir }

  describe '.suggestions' do
    subject { ::Spellr::NullSuggester.suggestions(token) }

    let(:word) { 'unword' } # spellr:disable-line
    let(:token) { ::Spellr::Token.new(word) }

    it { is_expected.to be_empty }
  end

  describe '.slow?' do
    subject { described_class }

    it { is_expected.to be_slow }
  end

  describe '.fast_suggestions' do
    subject { ::Spellr::NullSuggester.fast_suggestions(token) }

    let(:word) { 'unword' } # spellr:disable-line
    let(:token) { ::Spellr::Token.new(word) }

    it { is_expected.to be_empty }
  end
end

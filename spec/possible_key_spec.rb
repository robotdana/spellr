# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/spellr/key_tuner/naive_bayes'

RSpec.describe PossibleKey do
  # This is just to appear simplecov.
  # When i refactor this i'll add more tests
  it 'might not be a character set' do
    expect(described_class.new('café').character_set).to be_nil
    expect(described_class.new('café').character_set_total).to be_zero

    expect(NaiveBayes.new.key?('café')).to be false
    expect(NaiveBayes.new.key?('a7cé2xX')).to be false
  end

  it 'can check different character sets' do
    expect(NaiveBayes.new.key?('XXXX1345ZZZZ1')).to be true
    expect(NaiveBayes.new.key?('xxxx1345zzzz')).to be true
  end
end

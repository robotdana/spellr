# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/spellr/key_tuner/stats'

RSpec.describe Stats do
  it 'can be called on the module' do
    expect(described_class.mean([1, 2, 3])).to eq(2)
  end

  it 'can be included in a class' do
    klass = Class.new do
      include Stats
    end

    expect(klass.new.send(:mean, [1, 2, 3])).to eq 2
  end

  describe '.mean' do
    it 'will find the mean of integers' do
      expect(described_class.mean([1, 2, 3])).to eq(2)
    end

    it 'will find the decimal mean of integers' do
      expect(described_class.mean([1, 2])).to eq(1.5)
    end

    it 'will find the mean of floats' do
      expect(described_class.mean([1.0, 2.0])).to eq(1.5)
    end

    it 'can be given a block' do
      expect(described_class.mean(%w{a aa aaa}, &:length)).to eq(2)
    end

    it 'will return zero for an empty array' do
      expect(described_class.mean([])).to eq(0)
    end

    it 'will return zero for an empty array with a block' do
      expect(described_class.mean([], &:length)).to eq(0)
    end
  end

  describe '.min' do
    it 'will find the min of integers' do
      expect(described_class.min([1, 2, 3])).to eq(1)
    end

    it 'will find the min of floats' do
      expect(described_class.min([1.0, 2.0])).to eq(1.0)
    end

    it 'can be given a block, returning the block value' do
      expect(described_class.min(%w{a aa aaa}, &:length)).to eq(1)
    end

    it 'will return zero for an empty array' do
      expect(described_class.min([])).to eq(0)
    end

    it 'will return zero for an empty array with a block' do
      expect(described_class.min([], &:length)).to eq(0)
    end
  end

  describe '.max' do
    it 'will find the max of integers' do
      expect(described_class.max([1, 2, 3])).to eq(3)
    end

    it 'will find the max of floats' do
      expect(described_class.max([1.0, 2.0])).to eq(2.0)
    end

    it 'can be given a block, returning the block value' do
      expect(described_class.max(%w{a aa aaa}, &:length)).to eq(3)
    end

    it 'will return zero for an empty array' do
      expect(described_class.max([])).to eq(0)
    end

    it 'will return zero for an empty array with a block' do
      expect(described_class.max([], &:length)).to eq(0)
    end
  end

  # i only kind of understand how variance and std deviation work.
  # this is just encoding the current behaviour
  describe '.variance' do
    it 'will find the variance of integers' do
      expect(described_class.variance([1, 2, 5]))
        .to be_within(0.000001).of(2.8888888)
    end

    it 'will find the variance of floats' do
      expect(described_class.variance([1.1, 2.2, 5.5]))
        .to be_within(0.000001).of(3.49555555)
    end

    it 'can be given a block returning the block value' do
      expect(described_class.variance(%w{a aa aaaaa}, &:length))
        .to be_within(0.000001).of(2.8888888)
    end

    it 'will return zero for an empty array' do
      expect(described_class.variance([])).to eq(0)
    end

    it 'will return zero for an empty array with a block' do
      expect(described_class.variance([], &:length)).to eq(0)
    end
  end

  describe '.standard_deviation' do
    it 'will find the standard_deviation of integers' do
      expect(described_class.standard_deviation([1, 2, 5]))
        .to be_within(0.000001).of(1.699673171197595)
    end

    it 'will find the standard_deviation of floats' do
      expect(described_class.standard_deviation([1.1, 2.2, 5.5]))
        .to be_within(0.000001).of(1.8696404883173543)
    end

    it 'can be given a block returning the block value' do
      expect(described_class.standard_deviation(%w{a aa aaaaa}, &:length))
        .to be_within(0.000001).of(1.699673171197595)
    end

    it 'will return zero for an empty array' do
      expect(described_class.standard_deviation([])).to eq(0)
    end

    it 'will return zero for an empty array with a block' do
      expect(described_class.standard_deviation([], &:length)).to eq(0)
    end
  end

  # i don't understand how gaussian probability works, this is just encoding the current behaviour
  describe '.gaussian_probability' do
    let(:boolean_probability) do
      {
        standard_deviation: 0,
        mean: 1,
        variance: 0
      }
    end

    let(:probability) do
      {
        standard_deviation: Math.sqrt(0.1),
        mean: 1,
        variance: 0.1
      }
    end

    it 'returns 1 when standard_deviation is 0 and the value matches the mean' do
      expect(described_class.gaussian_probability(1, **boolean_probability)).to eq 1.0
    end

    it 'returns 0 when standard_deviation is 0 and the value is not the mean' do
      expect(described_class.gaussian_probability(0, **boolean_probability)).to eq 0.0
    end

    it 'is likely when the value is similar' do
      expect(
        described_class.gaussian_probability(0.9, **probability)
      ).to be_within(0.000001).of(1.2000389484301361)
    end

    it 'is likely when the value is different' do
      expect(
        described_class.gaussian_probability(0.0, **probability)
      ).to be_within(0.000001).of(0.008500366602520345)
    end

    it 'is impossible when the value is wildly different' do
      expect(
        described_class.gaussian_probability(1000, **probability)
      ).to be_within(0.000001).of(0.0)
    end
  end
end

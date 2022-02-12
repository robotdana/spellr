# frozen_string_literal: true

require_relative '../backports'

module Stats
  module_function

  extend Math

  def mean(values, &block)
    return 0 if values.empty?

    values.sum(&block).to_f / values.length
  end

  def min(values, &block)
    return 0 if values.empty?
    return values.min unless block_given?

    yield values.min_by(&block)
  end

  def max(values, &block)
    return 0 if values.empty?
    return values.max unless block_given?

    yield values.max_by(&block)
  end

  def variance(values, &block)
    return 0 if values.empty?

    mean = mean(values, &block)
    values.sum do |value|
      value = yield value if block_given?
      (mean - value)**2
    end.to_f / values.length
  end

  def standard_deviation(values, &block)
    sqrt(variance(values, &block))
  end

  def gaussian_probability(value, standard_deviation:, mean:, variance:)
    # deal with the edge case of a 0 standard deviation
    if standard_deviation == 0
      return mean == value ? 1.0 : 0.0
    end

    # calculate the gaussian probability
    exp = -((value - mean)**2) / (2 * variance)
    (1.0 / sqrt(2 * Math::PI * variance)) * (Math::E**exp)
  end
end

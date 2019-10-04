# frozen_string_literal: true

module Stats
  def mean(values, &block)
    return 0 if values.empty?

    values.sum(&block || :itself).to_f / values.length
  end

  def min(values, &block)
    return 0 if values.empty?

    block ||= :itself.to_proc
    block.call(values.min_by(&block))
  end

  def max(values, &block)
    return 0 if values.empty?

    block ||= :itself.to_proc
    block.call(values.max_by(&block))
  end

  def variance(values, &block)
    return 0 if values.empty?

    values.sum { |sample| (mean(values, &block) - (block ? block.call(sample) : sample))**2 }.to_f / values.length
  end

  def standard_deviation(values, &block)
    Math.sqrt(variance(values, &block))
  end
end

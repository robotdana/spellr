# frozen_string_literal: true

module Eventually
  class << self
    def equal?(value, seconds)
      loop_within(seconds) do
        output = yield
        return true if output == value
      end
      false
    end

    private

    def loop_within(seconds)
      # timeout is just because it gets stuck sometimes
      Timeout.timeout(seconds + 1) do
        start_time = monotonic_time
        yield until start_time + seconds < monotonic_time
      end
    end

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end

RSpec::Matchers.define :eventually_eq do |expected, wait: 2|
  match do |actual|
    Eventually.equal?(expected, wait, &actual)

    @actual = actual.call
    expect(@actual).to eq(expected)
  end

  diffable
  supports_block_expectations
end

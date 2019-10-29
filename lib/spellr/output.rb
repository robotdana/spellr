# frozen_string_literal: true

module Spellr
  class Output
    attr_reader :exit_code

    def initialize
      @exit_code = 0
    end

    def stdin
      @stdin ||= $stdin
    end

    def stdout
      @stdout ||= $stdout
    end

    def stderr
      @stderr ||= $stderr
    end

    def stdout?
      defined?(@stdout)
    end

    def stderr?
      defined?(@stderr)
    end

    def counts
      @counts ||= Hash.new(0)
    end

    def exit_code=(value)
      @exit_code = value unless value.zero?
    end

    def increment(counter)
      counts[counter] += 1
    end

    def puts(str)
      stdout.puts(str)
    end

    def warn(str)
      stderr.puts(str)
    end

    def print(str)
      stdout.print(str)
    end

    def <<(other) # rubocop:disable Metrics/AbcSize
      self.exit_code = other.exit_code
      stderr.puts other.stderr.string if other.stderr?
      stdout.puts other.stdout.string if other.stdout?
      counts.merge!(other.counts) { |_k, a, b| a + b }
    end
  end
end

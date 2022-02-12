# frozen_string_literal: true

require 'tty_string'
require_relative 'eventually'

class ExitStatus
  def initialize(pid)
    @pid = pid
  end

  def ==(other)
    Eventually.equal?(other, 3) { status }
  end

  def status
    @status ||= PTY.check(@pid)&.exitstatus
  end

  def inspect
    status.inspect
  end
end

# just so i get a nice diff.
RSpec::Matchers.define :have_output do |expected|
  match do |actual|
    actual == expected # rubocop:disable Lint/Void i'm doing naughty things.

    @actual = actual.to_s
    expect(@actual).to eq(expected)
  end

  diffable
end

# just so i get a nice diff.
RSpec::Matchers.define :have_unordered_output do |expected|
  match do |actual|
    @actual = TTYString.new(actual, clear_style: false).to_s.split("\n")
    expect(@actual).to match_array(expected.to_s.split("\n"))
  end

  diffable
end

module StringIOStringMethods
  def ==(other)
    to_s == other
  end

  def to_s
    TTYString.new(string, clear_style: false).to_s
  end

  def to_str
    to_s
  end

  def inspect
    string.inspect
  end

  def empty?
    string.empty?
  end

  def each_line(&block)
    to_s.each_line(&block)
  end

  def readlines
    string.each_line.to_a
  end
end

module IOStringMethods
  def string
    @string ||= ''
    @string += read_nonblock(4096)
  rescue IO::WaitReadable
    (readable? && retry) || @string
  rescue Errno::EIO, IOError
    @string
  end

  def ==(other)
    Eventually.equal?(other, 4) { to_s }
  end

  def readable?
    IO.select([self], nil, nil, 0)
  end

  def empty?
    sleep 0.1
    string.empty?
  end
end

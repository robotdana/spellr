# frozen_string_literal: true

require 'open3'
require 'pty'
require 'tty_string'
require_relative '../../lib/spellr/string_format'

RSpec::Matchers.define :print do |expected|
  match do |actual|
    loop_within_or_match(2, expected) do
      @actual = render_io(actual)
    end

    expect(@actual).to eq(expected)
  end

  diffable
end

RSpec::Matchers.define :have_exitstatus do |expected|
  match do |actual|
    loop_within_or_match(2, expected) do
      @actual = PTY.check(actual)&.exitstatus
    end

    expect(@actual).to eq(expected)
  end

  diffable
end

module CLIHelper
  EXE_PATH = ::File.expand_path('../../exe', __dir__).freeze
  def self.included(base)
    base.include Spellr::StringFormat
  end
  attr_reader :result

  def run(cmd, &block)
    if block_given?
      PTY.spawn("#{EXE_PATH}/#{cmd}", &block)
    else
      @stdout, @stderr, @status = Open3.capture3("#{EXE_PATH}/#{cmd}")
    end
  end

  def loop_within_or_match(seconds, value)
    loop_within(seconds) do
      output = yield
      return output if output == value
    end
  end

  def loop_within(seconds)
    # timeout is just because it gets stuck sometimes
    Timeout.timeout(seconds * 10) do
      start_time = monotonic_time
      yield until start_time + seconds < monotonic_time
    end
  end

  def monotonic_time
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def render_io(io, clear_style: false, process_cursor: true)
    string = accumulate_io(io)
    return string unless process_cursor

    TTYString.new(string, clear_style: clear_style).to_s
  end

  def accumulate_io(io)
    @accumulate_io ||= {}
    @accumulate_io[io] ||= ''
    @accumulate_io[io] += read_while_readable(io)
  end

  def read_while_readable(io, str = '')
    str += io.read_nonblock(4096)
  rescue IO::WaitReadable
    (readable?(io) && retry) || str
  rescue EOFError, Errno::EIO
    str
  end

  def readable?(io)
    IO.select([io], nil, nil, 0)
  end

  def stdout
    @stdout.chomp
  end

  def stderr
    @stderr&.chomp
  end

  def exitstatus
    @status.exitstatus
  end
end

RSpec.configure do |c|
  c.include CLIHelper, type: :cli
end

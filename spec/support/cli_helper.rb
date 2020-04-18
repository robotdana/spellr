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

    expect(@actual.chomp).to eq(expected.chomp)
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

  def run_exe(cmd, &block) # rubocop:disable Metrics/MethodLength
    exe = if defined?(SimpleCov)
      "ruby -r./spec/support/pre_pty.rb exe/#{cmd}"
    else
      "exe/#{cmd}"
    end

    run(exe, &block)
  end

  def run_bin(cmd, &block) # rubocop:disable Metrics/MethodLength
    exe = if defined?(SimpleCov)
      "ruby -r./spec/support/pre_pty.rb -r./spec/support/mock_generate.rb bin/#{cmd}"
    else
      "ruby -r./spec/support/mock_generate.rb bin/#{cmd}"
    end

    run(exe, &block)
  end

  def run_rake(cmd = nil, &block) # rubocop:disable Metrics/MethodLength
    exe = if defined?(SimpleCov)
      "rake -r./spec/support/pre_pty.rb -f #{Dir.pwd}/Rakefile #{cmd}"
    else
      "rake -f #{Dir.pwd}/Rakefile #{cmd}"
    end
    run(exe, &block)
  end

  def run(cmd, &block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    env = {
      'SPELLR_TEST_PWD' => Dir.pwd,
      'SPELLR_TEST_DESCRIPTION' => @_example.full_description.tr(' /', '__')
    }

    Dir.chdir("#{__dir__}/../../") do
      if block_given?
        stderr_reader, stderr_writer = IO.pipe
        PTY.spawn(env, cmd, err: stderr_writer.fileno) do |stdout, stdin, pid|
          block.call(stdout, stdin, pid, stderr_reader)

          sleep 0.1 if defined?(SimpleCov) # it just needs a moment

          stdout.close
          stderr_reader.close
          stderr_writer.close
          stdin.close
        end
      else
        @stdout, @stderr, @status = Open3.capture3(env, cmd)
      end
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
  c.before do |example|
    @_example = example
  end
  c.include CLIHelper, type: :cli
end

# frozen_string_literal: true

require 'open3'
require 'pty'
require 'shellwords'

require_relative 'io_string_methods'

require_relative '../../lib/spellr/cli'
require_relative '../../lib/spellr/output_stubbed'
require_relative '../../lib/spellr/string_format'

module CLIHelper
  def self.included(base)
    base.include Spellr::StringFormat
  end

  def spellr(argv = '', &block) # rubocop:disable Metrics/MethodLength
    if block_given?
      run("ruby ./exe/spellr #{argv}", &block)
    else
      stub_config(output: output)

      @exitstatus = Spellr::CLI.new(Shellwords.split(argv)).run
    end
  end

  def run_bin(cmd, &block)
    run("ruby -r./spec/support/mock_generate.rb ./bin/#{cmd}", &block)
  end

  def run_rake(task = nil, &block)
    run("rake -f #{Spellr.pwd}/Rakefile #{task}", &block)
  end

  def insert_pre_pty(cmd)
    cmd, args = cmd.split(' ', 2)
    "#{cmd} -r./spec/support/pre_pty.rb #{args}"
  end

  def run(cmd, &block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    cmd = insert_pre_pty(cmd)
    env = {
      'SPELLR_TEST_PWD' => Spellr.pwd_s,
      'SPELLR_TEST_DESCRIPTION' => @_example.full_description.tr(' /', '__')
    }
    env['SPELLR_SIMPLECOV'] = '1' if defined?(SimpleCov)

    if block_given?
      stderr_reader, stderr_writer = IO.pipe
      PTY.spawn(env, cmd, err: stderr_writer.fileno) do |stdout, stdin, pid|
        stdout.extend(StringIOStringMethods)
        stdout.extend(IOStringMethods)

        stderr_reader.extend(StringIOStringMethods)
        stderr_reader.extend(IOStringMethods)

        @stdout = stdout
        @stderr = stderr_reader
        @stdin = stdin
        @exitstatus = ExitStatus.new(pid)

        block.call(stdout, stdin, stderr_reader)

        sleep 0.1 if defined?(SimpleCov) # it just needs a moment

        stdout.close
        stderr_reader.close
        stderr_writer.close
        stdin.close
      end
    else
      @stdout, @stderr, status = Open3.capture3(env, cmd)
      @exitstatus = status.exitstatus
    end
  end

  def output
    @output ||= Spellr::OutputStubbed.new
  end

  def stdout
    @stdout ||= output.stdout.tap { |s| s.extend(StringIOStringMethods) }
  end

  def stdin
    @stdin ||= output.stdin
  end

  def stderr
    @stderr ||= output.stderr.tap { |s| s.extend(StringIOStringMethods) }
  end

  def exitstatus
    @exitstatus
  end
end

RSpec.configure do |c|
  c.before do |example|
    @_example = example
  end

  c.after(type: :cli) do
    stdin.close if stdin.respond_to?(:close)
    stdout.close if stdout.respond_to?(:close)
    stderr.close if stderr.respond_to?(:close)
  end

  c.include CLIHelper, type: :cli
end

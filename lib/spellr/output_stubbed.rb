# frozen_string_literal: true

require 'stringio'
require_relative 'output'

module Spellr
  class OutputStubbed < Spellr::Output
    def stdin
      @stdin ||= StringIO.new
    end

    def stdout
      @stdout ||= StringIO.new
    end

    def stderr
      @stderr ||= StringIO.new
    end

    def marshal_dump # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      l_exit_code = @exit_code if defined?(@exit_code)
      l_counts = @counts if defined?(@counts)
      l_stdin = @stdin if defined?(@stdin)
      l_stdout = @stdout if defined?(@stdout)
      l_stderr = @stderr if defined?(@stderr)

      {
        exit_code: l_exit_code,
        counts: l_counts,
        stdin: l_stdin&.string,
        stdin_pos: l_stdin&.pos,
        stdout: l_stdout&.string,
        stdout_pos: l_stdout&.pos,
        stderr: l_stderr&.string,
        stderr_pos: l_stderr&.pos
      }
    end

    def marshal_load(dumped) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      if dumped[:stdin]
        @stdin = StringIO.new(dumped[:stdin])
        @stdin.pos = dumped[:stdin_pos]
      end

      if dumped[:stdout]
        @stdout = StringIO.new(dumped[:stdout])
        @stdout.pos = dumped[:stdout_pos]
      end

      if dumped[:stderr]
        @stderr = StringIO.new(dumped[:stderr])
        @stderr.pos = dumped[:stderr_pos]
      end

      @exit_code = dumped[:exit_code] if dumped[:exit_code]
      @counts = dumped[:counts] if dumped[:counts]
    end
  end
end

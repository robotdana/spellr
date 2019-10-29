# frozen_string_literal: true

require_relative 'output'

module Spellr
  class OutputStubbed < Spellr::Output
    attr_accessor :exit_code

    def initialize
      @exit_code = 0
    end

    def stdin
      @stdin ||= StringIO.new
    end

    def stdout
      @stdout ||= StringIO.new
    end

    def stderr
      @stderr ||= StringIO.new
    end

    def marshal_dump # rubocop:disable Metrics/MethodLength
      {
        exit_code: exit_code,
        counts: @counts,
        stdin: @stdin&.string,
        stdin_pos: @stdin&.pos,
        stdout: @stdout&.string,
        stdout_pos: @stdout&.pos,
        stderr: @stderr&.string,
        stderr_pos: @stderr&.pos
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

      @exit_code = dumped[:exit_code]
      @counts = dumped[:counts]
    end
  end
end

# frozen_string_literal: true

require 'rake'
require 'shellwords'

module Spellr
  class RakeTask
    include ::Rake::DSL

    def self.generate_task(name = :spellr, *default_argv) # rubocop:disable
      new(name, default_argv)

      name
    end

    def initialize(name, default_argv)
      @name = name
      @default_argv = default_argv

      describe_task
      define_task
    end

    private

    def escaped_argv(argv = @default_argv)
      return if argv.empty?

      Shellwords.shelljoin(argv)
    end

    def describe_task
      return desc('Run spellr') if @default_argv.empty?

      desc("Run spellr (default args: #{escaped_argv})")
    end

    def define_task # rubocop:disable Metrics/MethodLength
      task(@name, :'*args') do |_, task_argv|
        with_utf_8 do
          argv = argv_or_default(task_argv)
          write_cli_cmd(argv)
          run(argv)
        end
      end
    end

    def write_cli_cmd(argv)
      $stdout.puts("\e[2mspellr #{escaped_argv(argv)}\e[0m")
    end

    def run(argv)
      require 'spellr/cli'
      status = Spellr::CLI.new(argv).run
      exit 1 unless status == 0
    end

    def argv_or_default(task_argv)
      task_argv = task_argv.to_a.compact
      task_argv.empty? ? @default_argv : task_argv
    end

    def with_utf_8 # rubocop:disable Metrics/MethodLength
      old_default_external = ::Encoding.default_external
      old_default_internal = ::Encoding.default_internal
      ::Encoding.default_external = ::Encoding::UTF_8
      ::Encoding.default_internal = ::Encoding::UTF_8
      yield
      ::Encoding.default_external = old_default_external
      ::Encoding.default_internal = old_default_internal
    end
  end
end

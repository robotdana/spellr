# frozen_string_literal: true

require 'open3'
require 'pty'
require_relative '../../lib/spellr/string_format'
require_relative 'tty_string'
require 'rspec/eventually'

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

  def accumulate_io(io, ignore_color: false, parse: true) # rubocop:disable Metrics/MethodLength
    @s ||= ''
    io.flush

    Timeout.timeout(0.1) do
      loop do
        @s += io.getc.to_s
      end
    end

    io.flush
  rescue Timeout::Error, EOFError, Errno::EIO
    retry if @s.empty?
    return @s unless parse

    TTYString.new(@s, ignore_color: ignore_color).to_s
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

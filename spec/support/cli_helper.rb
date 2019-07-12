# frozen_string_literal: true

require 'open3'

module CLIHelper
  EXE_PATH = ::File.expand_path('../../exe', __dir__).freeze

  attr_reader :result

  def run(cmd)
    @stdout, @stderr, @status = Open3.capture3("#{EXE_PATH}/#{cmd}")
  end

  def stdout
    @stdout.chomp
  end

  def stderr
    @stderr.chomp
  end

  def exitstatus
    @status.exitstatus
  end
end

RSpec.configure do |c|
  c.include CLIHelper, type: :cli
end

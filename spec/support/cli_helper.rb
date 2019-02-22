require 'rspec_command'
module CLIHelper
  EXE_PATH = File.expand_path('../../../exe', __FILE__).freeze

  def run(cmd)
    @result = command("#{EXE_PATH}/#{cmd}")
  end

  def result
    @result
  end

  def stdout
    format_output(@result.stdout)
  end

  def stderr
    format_output(@result.stderr)
  end

  def exitstatus
    @result.exitstatus
  end

  def format_output(output)
    array = output.lines.map(&:chomp)
    array.length == 1 ? array.first : array
  end

  def without_temp_path(files)
    files.map { |file| file.sub("/private#{temp_path}/", '') }
  end
end

RSpec.configure do |c|
  c.include RSpecCommand, type: :cli
  c.include CLIHelper, type: :cli
end

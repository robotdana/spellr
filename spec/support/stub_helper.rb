# frozen_string_literal: true

require 'pathname'
require 'tmpdir'
require_relative '../../lib/spellr'

module StubHelper
  def stub_config(**configs)
    unless defined?(@stubbed_config)
      allow(Spellr).to receive_messages(config: Spellr::Config.new)
      @stubbed_config = true
    end
    allow(Spellr.config).to receive_messages(configs)
  end

  def with_temp_dir
    dirname = "#{@_example.full_description.tr(' /', '__-')}_#{rand.to_s[2..-1]}"
    dir = Pathname.new("#{__dir__}/../../tmp/#{dirname}").expand_path
    dir.mkpath
    @_temp_dir = dir
    allow(Spellr).to receive_messages(pwd: @_temp_dir, pwd_s: @_temp_dir.to_s)
  end

  def stub_fs_file_list(filenames)
    filenames.each do |filename|
      stub_fs_file(filename)
    end
  end

  def stub_fs_file(filename, body = '')
    path = Spellr.pwd.join(filename)
    path.parent.mkpath
    path.write(body)
    path
  end
end

RSpec.configure do |config|
  config.before do |example|
    @_example = example
  end
  config.include StubHelper
  config.after do
    @_temp_dir.rmtree if defined?(@_temp_dir)
  end
end

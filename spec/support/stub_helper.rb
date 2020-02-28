# frozen_string_literal: true

require 'pathname'
require 'tmpdir'
require_relative '../../lib/spellr'

module StubHelper
  def stub_config(**configs)
    allow(Spellr.config).to receive_messages(configs)
  end

  def with_temp_dir(example) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    dirname = "#{example.full_description.tr(' /', '__-')}_#{rand.to_s[2..-1]}"
    dir = Pathname.new(__dir__).join('..', '..', 'tmp', dirname).expand_path
    dir.mkpath
    dir = dir
    Dir.chdir(dir.to_s) { example.run }
  ensure
    dir.rmtree
    Spellr.config.send(:clear_pwd)
  end

  def stub_fs_file_list(filenames)
    filenames.each do |filename|
      stub_fs_file(filename)
    end
  end

  def stub_fs_file(filename, body = '')
    path = Pathname.pwd.join(filename)
    path.parent.mkpath
    path.write(body)
    path
  end
end

RSpec.configure do |config|
  config.include StubHelper
end

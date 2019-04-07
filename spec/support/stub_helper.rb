# frozen_string_literal: true

module StubHelper
  def stub_config(**configs)
    allow(Spellr.config).to receive_messages(configs)
  end

  def with_temp_dir(&block)
    dir = Pathname.new(Dir.mktmpdir)
    Dir.chdir(dir, &block)
  ensure
    dir.rmtree
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

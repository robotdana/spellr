module StubHelper
  def stub_file(tokens: [], dictionaries: [])
    double = instance_double(Spellr::File, dictionaries: dictionaries)
    allow(double).to receive(:each_line) { |&block| block.call(stub_line(tokens: tokens)) }
    double
  end

  def stub_line(tokens: [])
    double = instance_double(Spellr::Line)
    allow(double).to receive(:each_token) { |&block| tokens.each(&block) }
    double
  end

  def stub_dictionary(lines, only: [], only_hashbangs: [])
    double = instance_double(Spellr::Dictionary, only: only, only_hashbangs: [])
    allow(double).to receive(:each) { |&block| lines.each_line(&block) }
    allow(double).to receive(:bsearch) { |&block| lines.lines.sort.bsearch(&block) }
    double.extend Enumerable
    double
  end

  def stub_reporter
    class_double(Spellr::Reporter, report: nil)
  end

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

module StubHelper
  def stub_file(tokens: [], dictionaries: [])
    double = instance_double(Spellr::File, dictionaries: dictionaries)
    allow(double).to receive(:each_token) { |&block| tokens.each(&block) }
    double
  end

  def stub_dictionary(lines, only: [])
    double = instance_double(Spellr::Dictionary, only: only)
    allow(double).to receive(:each) { |&block| lines.each_line(&block) }
    double.extend Enumerable
    double
  end

  def stub_reporter
    class_double(Spellr::Reporter, report: nil)
  end

  def stub_config(**configs)
    allow(Spellr.config).to receive_messages(configs)
  end
end

RSpec.configure do |config|
  config.include StubHelper
end

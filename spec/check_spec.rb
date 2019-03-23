RSpec::Matchers.define :include_spelling_errors do |*expected|
  match do |actual|
    @actual = []

    allow(Spellr.config.reporter).to receive(:report) { |arg| @actual << arg }

    file = stub_file(tokens: actual.map { |a| Spellr::Token.new(a) }, dictionaries: [dictionary])
    Spellr::Check.new(files: [file]).check

    expect(@actual).to match(expected)
  end

  diffable
end

RSpec.describe Spellr::Check do
  describe '#check_token' do
    let(:dictionary) do
      stub_dictionary <<~DICTIONARY
        foo
        bar
      DICTIONARY
    end

    it "reports missing tokens" do
      expect(['foo', 'bar', 'baz']).to include_spelling_errors "baz"
    end

    it "reports missing uppercase tokens" do
      expect(['FOO', 'BAR', 'BAZ']).to include_spelling_errors "BAZ"
    end

    it "accepts joint words" do
      expect(["foobar", "barbaz"]).to include_spelling_errors "barbaz"
    end
  end
end

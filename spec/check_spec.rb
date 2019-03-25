# frozen_string_literal: true

RSpec::Matchers.define :include_spelling_errors do |*expected|
  match do |actual|
    @actual = []

    file = stub_file(tokens: actual.map { |a| Spellr::Token.new(a) }, dictionaries: [dictionary])
    check = Spellr::Check.new(files: [file])

    allow(check.reporter).to receive(:call) { |arg| @actual << arg }
    check.check

    expect(@actual).to match(expected)
  end

  diffable
end

RSpec.describe Spellr::Check do
  describe '#check' do
    let(:dictionary) do
      stub_dictionary <<~DICTIONARY
        bar
        foo
      DICTIONARY
    end

    it 'reports missing tokens' do
      expect(%w{foo bar baz}).to include_spelling_errors 'baz'
    end

    it 'reports missing uppercase tokens' do
      expect(%w{FOO BAR BAZ}).to include_spelling_errors 'BAZ'
    end

    it 'accepts joint words' do
      expect(%w{foobar barbaz}).to include_spelling_errors 'barbaz'
    end
  end
end

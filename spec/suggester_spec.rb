# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/spellr/maybe_suggester'
require_relative '../lib/spellr/token'
require_relative '../lib/spellr/tokenizer'

RSpec.describe Spellr::Suggester do
  RSpec::Matchers.define :have_suggestions do |*expected|
    match do |actual|
      @actual = ::Spellr::Suggester.suggestions(::Spellr::Token.new(actual))
      expect(@actual).to match(expected)
    end

    diffable
  end
  RSpec::Matchers.define :have_fast_suggestions do |*expected|
    match do |actual|
      @actual = ::Spellr::Suggester.fast_suggestions(::Spellr::Token.new(actual))
      expect(@actual).to match(expected)
    end

    diffable
  end
  RSpec::Matchers.alias_matcher :have_no_suggestions, :have_suggestions
  RSpec::Matchers.alias_matcher :have_no_fast_suggestions, :have_fast_suggestions

  describe '.suggestions' do
    it 'provides suggestions' do
      expect('unword')
        .to have_suggestions('unworded', 'unworked', 'unwormed', 'unwork', 'unworn')
    end

    it 'provides suggestions with an uppercase word' do
      expect('UNWORD')
        .to have_suggestions('UNWORDED', 'UNWORKED', 'UNWORMED', 'UNWORK', 'UNWORN')
    end

    it 'provides suggestions with a titlecase word' do
      expect('Unword')
        .to have_suggestions('Unworded', 'Unworked', 'Unwormed', 'Unwork', 'Unworn')
    end

    it 'provides suggestions with an unfamiliar case word, defaulting to lowercase' do
      expect('UnWord')
        .to have_suggestions('unworded', 'unworked', 'unwormed', 'unwork', 'unworn')
    end

    it 'provides suggestions for dolar' do
      expect('dolar')
        .to have_suggestions('dollar', 'dola')
    end

    it 'provides suggestions for foa' do
      expect('foa')
        .to have_suggestions('foal', 'foam', 'fola')
    end

    it 'provides suggestions for acn' do
      expect('acn')
        .to have_suggestions('acne')
    end

    it 'provides suggestions for donoore' do
      expect('donoore')
        .to have_suggestions('donor')
    end

    it 'provides suggestions for antoeuhealheuo' do
      expect('antoeuheapl')
        .to have_suggestions('antechapel')
    end

    it 'provides suggestions for dolares' do
      expect('dolares')
        .to have_suggestions('doles', 'dollars', 'dolores')
    end

    it 'provides suggestions for amet' do
      expect('amet')
        .to have_suggestions('ament', 'armet')
    end

    it 'provides suggestions for hellooo' do
      expect('hellooo')
        .to have_suggestions('hello')
    end

    it 'provides suggestions for thiswordisoutsidethethreshould' do
      expect('thiswordisoutsidethethreshould')
        .to have_no_suggestions
    end

    it 'returns empty' do
      expect('thisisanimpossibleword')
        .to have_no_suggestions
    end

    context 'when the file is ruby' do
      before { with_temp_dir }

      let(:file) do
        stub_fs_file 'foo.rb', 'constx'
        Spellr::File.new(Spellr.pwd.join('foo.rb'))
      end

      let(:token) do
        Spellr::Tokenizer.new(file).enum_for(:each_token).first
      end

      it 'gives suggestions relevant to ruby' do
        expect(::Spellr::Suggester.suggestions(token)).to eq(['const'])
      end
    end
  end

  describe '.slow?' do
    subject { described_class }

    before do
      described_class.slow? # ensure the instance variable is there to remove
      described_class.remove_instance_variable(:@slow)
      allow(::JaroWinkler).to receive(:method).with(:similarity)
        .and_return(instance_double(Method, source_location: source_location))
    end

    after do
      described_class.remove_instance_variable(:@slow)
    end

    context 'with ruby JaroWinkler.similarity' do
      let(:source_location) { 'describe.rb' }

      it { is_expected.to be_slow }

      it 'is memoized' do
        expect(subject).to be_slow
        allow(::JaroWinkler).to receive(:method).with(:similarity)
          .and_return(instance_double(Method, source_location: nil))
        expect(subject).to be_slow
      end
    end

    context 'with c JaroWinkler.similarity' do
      let(:source_location) { nil }

      it { is_expected.not_to be_slow }

      it 'is memoized' do
        expect(subject).not_to be_slow
        allow(::JaroWinkler).to receive(:method).with(:similarity)
          .and_return(instance_double(Method, source_location: 'whatever.rb'))
        expect(subject).not_to be_slow
      end
    end
  end

  describe '.fast_suggestions' do
    it 'has suggestions' do
      expect('unword')
        .to have_fast_suggestions('unworded', 'unworked', 'unwormed', 'unwork', 'unworn')
    end

    context 'with slow fast_suggestions' do
      before do
        allow(described_class).to receive(:slow?).and_return(true)
      end

      it 'has no suggestions' do
        expect('unword')
          .to have_no_fast_suggestions
      end
    end
  end
end

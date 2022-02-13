# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/spellr/suggester'
require_relative '../lib/spellr/token'
require_relative '../lib/spellr/tokenizer'

RSpec.describe Spellr::Suggester do
  before { with_temp_dir }

  describe '.suggestions' do
    subject { ::Spellr::Suggester.suggestions(token) }

    let(:word) { 'unword' } # spellr:disable-line
    let(:token) { ::Spellr::Token.new(word) }

    it { is_expected.to eq %w{unworded unworked unwormed unwork unworn} }

    context 'with uppercase word' do
      let(:word) { 'UNWORD' } # spellr:disable-line

      it { is_expected.to eq %w{UNWORDED UNWORKED UNWORMED UNWORK UNWORN} }
    end

    context 'with titlecase word' do
      let(:word) { 'Unword' } # spellr:disable-line

      it { is_expected.to eq %w{Unworded Unworked Unwormed Unwork Unworn} }
    end

    context 'with an unfamiliar case word' do
      let(:word) { 'UnWord' }

      it 'defaults to lowercase' do
        expect(subject).to eq %w{unworded unworked unwormed unwork unworn}
      end
    end

    context 'with an impossible word' do
      let(:word) { 'thisisanimpossibleword' } # spellr:disable-line

      it { is_expected.to be_empty }
    end

    context 'when the file is ruby' do
      let(:file) do
        stub_fs_file 'foo.rb', 'constx' # spellr:disable-line
        Spellr::File.new(Spellr.pwd.join('foo.rb'))
      end

      let(:token) do
        Spellr::Tokenizer.new(file).enum_for(:each_token).first
      end

      it 'gives suggestions relevant to ruby' do
        expect(subject).to eq ['const']
      end
    end
  end

  describe '.slow?' do
    subject { described_class }

    before do
      described_class.slow? # ensure the instance variable is there to remove
      described_class.remove_instance_variable(:@slow)
      allow(::JaroWinkler).to receive(:method).with(:distance)
        .and_return(instance_double(Method, source_location: source_location))
    end

    after do
      described_class.remove_instance_variable(:@slow)
    end

    context 'with ruby JaroWinkler.describe' do
      let(:source_location) { 'describe.rb' }

      it { is_expected.to be_slow }

      it 'is memoized' do
        expect(subject).to be_slow
        allow(::JaroWinkler).to receive(:method).with(:distance)
          .and_return(instance_double(Method, source_location: nil))
        expect(subject).to be_slow
      end
    end

    context 'with c JaroWinkler.describe' do
      let(:source_location) { nil }

      it { is_expected.not_to be_slow }

      it 'is memoized' do
        expect(subject).not_to be_slow
        allow(::JaroWinkler).to receive(:method).with(:distance)
          .and_return(instance_double(Method, source_location: 'whatever.rb'))
        expect(subject).not_to be_slow
      end
    end
  end

  describe '.fast_suggestions' do
    subject { ::Spellr::Suggester.fast_suggestions(token) }

    let(:word) { 'unword' } # spellr:disable-line
    let(:token) { ::Spellr::Token.new(word) }

    it { is_expected.to eq %w{unworded unworked unwormed unwork unworn} }

    context 'with slow fast_suggestions' do
      before do
        allow(described_class).to receive(:slow?).and_return(true)
      end

      it { is_expected.to be_empty }
    end
  end
end

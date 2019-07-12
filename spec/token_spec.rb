# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/spellr/token'
require_relative '../lib/spellr/tokenizer'
require_relative '../lib/spellr/file'

RSpec.describe Spellr::Token do
  describe '#replace' do
    around { |example| with_temp_dir { example.run } }

    let(:file) do
      stub_fs_file 'foo', "first line\nsecond line"
      Spellr::File.new(Pathname.pwd.join('foo'))
    end

    let(:tokens) do
      Spellr::Tokenizer.new(file).enum_for(:each_token).to_a
    end

    it 'can replace a token at the beginning' do
      tokens[0].replace('initial')

      expect(file.read).to eq "initial line\nsecond line"
    end

    it 'can replace a token at the beginning of another line' do
      tokens[2].replace('subsequent')

      expect(file.read).to eq "first line\nsubsequent line"
    end

    it 'can replace the last token' do
      tokens[3].replace('row')

      expect(file.read).to eq "first line\nsecond row"
    end
  end
end

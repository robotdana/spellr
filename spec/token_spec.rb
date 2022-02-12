# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/spellr/token'
require_relative '../lib/spellr/tokenizer'
require_relative '../lib/spellr/file'

RSpec.describe Spellr::Token do
  before { with_temp_dir }

  let(:file) do
    stub_fs_file 'foo', "first line\n  second line\n🤷🏼‍♀️ 🇳🇿 char vs byte\ncafé"
    Spellr::File.new(Spellr.pwd.join('foo'))
  end

  let(:tokens) do
    Spellr::Tokenizer.new(file).enum_for(:each_token).to_a
  end

  describe '#replace' do
    it 'can replace a token at the beginning' do
      tokens[0].replace('initial')

      expect(file.read).to eq "initial line\n  second line\n🤷🏼‍♀️ 🇳🇿 char vs byte\ncafé"
    end

    it 'can replace a token at the beginning of another line' do
      tokens[2].replace('subsequent')

      expect(file.read).to eq "first line\n  subsequent line\n🤷🏼‍♀️ 🇳🇿 char vs byte\ncafé"
    end

    it 'can replace the token after a multibyte char' do
      tokens[4].replace('character')

      expect(file.read).to eq "first line\n  second line\n🤷🏼‍♀️ 🇳🇿 character vs byte\ncafé"
    end

    it 'can replace the last token' do
      tokens[6].replace('cafe')

      expect(file.read).to eq "first line\n  second line\n🤷🏼‍♀️ 🇳🇿 char vs byte\ncafe"
    end
  end

  describe '#location' do
    it 'has a sense of location for the first token' do
      expect(tokens[0].location.line_number).to be 1
      expect(tokens[0].location.char_offset).to be 0
      expect(tokens[0].location.byte_offset).to be 0
      expect(tokens[0].location.absolute_char_offset).to be 0
      expect(tokens[0].location.absolute_byte_offset).to be 0
      expect(tokens[0].char_range).to eq 0...5
      expect(tokens[0].byte_range).to eq 0...5
      expect(tokens[0].file_char_range).to eq 0...5
      expect(tokens[0].file_byte_range).to eq 0...5
    end

    it 'has a sense of location for the second token on the first line' do
      expect(tokens[1].location.line_number).to be 1
      expect(tokens[1].location.char_offset).to be 6
      expect(tokens[1].location.byte_offset).to be 6
      expect(tokens[1].location.absolute_char_offset).to be 6
      expect(tokens[1].location.absolute_byte_offset).to be 6
      expect(tokens[1].char_range).to eq 6...10
      expect(tokens[1].byte_range).to eq 6...10
      expect(tokens[1].file_char_range).to eq 6...10
      expect(tokens[1].file_byte_range).to eq 6...10
    end

    it 'has a sense of location for the indented first token on the second line' do
      expect(tokens[2].location.line_number).to be 2
      expect(tokens[2].location.char_offset).to be 2
      expect(tokens[2].location.byte_offset).to be 2
      expect(tokens[2].location.absolute_char_offset).to be 13
      expect(tokens[2].location.absolute_byte_offset).to be 13
      expect(tokens[2].char_range).to eq 2...8
      expect(tokens[2].byte_range).to eq 2...8
      expect(tokens[2].file_char_range).to eq 13...19
      expect(tokens[2].file_byte_range).to eq 13...19
    end

    it 'has a sense of location for the indented second token on the second line' do
      expect(tokens[3].location.line_number).to be 2
      expect(tokens[3].location.char_offset).to be 9
      expect(tokens[3].location.byte_offset).to be 9
      expect(tokens[3].location.absolute_char_offset).to be 20
      expect(tokens[3].location.absolute_byte_offset).to be 20
      expect(tokens[3].char_range).to eq 9...13
      expect(tokens[3].byte_range).to eq 9...13
      expect(tokens[3].file_char_range).to eq 20...24
      expect(tokens[3].file_byte_range).to eq 20...24
    end

    it 'has a sense of location for the first token after multibyte emoji on the third line' do
      expect(tokens[4].location.line_number).to be 3
      expect(tokens[4].location.char_offset).to be 9
      expect(tokens[4].location.byte_offset).to be 27
      expect(tokens[4].location.absolute_char_offset).to be 34
      expect(tokens[4].location.absolute_byte_offset).to be 52
      expect(tokens[4].char_range).to eq 9...13
      expect(tokens[4].byte_range).to eq 27...31
      expect(tokens[4].file_char_range).to eq 34...38
      expect(tokens[4].file_byte_range).to eq 52...56
    end

    it 'has a sense of location for the second token after multibyte emoji on the third line' do
      expect(tokens[5].location.line_number).to be 3
      expect(tokens[5].location.char_offset).to be 17
      expect(tokens[5].location.byte_offset).to be 35
      expect(tokens[5].location.absolute_char_offset).to be 42
      expect(tokens[5].location.absolute_byte_offset).to be 60
      expect(tokens[5].char_range).to eq 17...21
      expect(tokens[5].byte_range).to eq 35...39
      expect(tokens[5].file_char_range).to eq 42...46
      expect(tokens[5].file_byte_range).to eq 60...64
    end

    it 'has a sense of location for the first multibyte token on the fourth line' do
      expect(tokens[6].location.line_number).to be 4
      expect(tokens[6].location.char_offset).to be 0
      expect(tokens[6].location.byte_offset).to be 0
      expect(tokens[6].location.absolute_char_offset).to be 47
      expect(tokens[6].location.absolute_byte_offset).to be 65
      expect(tokens[6].char_range).to eq 0...4
      expect(tokens[6].byte_range).to eq 0...5
      expect(tokens[6].file_char_range).to eq 47...51
      expect(tokens[6].file_byte_range).to eq 65...70
    end
  end

  describe '#case_method' do
    it 'can recognize lowercase' do
      expect(described_class.new('word').case_method).to eq :downcase
    end

    it 'can recognize title case' do
      expect(described_class.new('Word').case_method).to eq :capitalize
    end

    it 'can recognize uppercase' do
      expect(described_class.new('WORD').case_method).to eq :upcase
    end

    it 'returns a method leaving unchanged for unrecognized case' do
      expect(described_class.new('WoRD').case_method).to eq :itself
      expect(described_class.new('مرحبا').case_method).to eq :itself # spellr:disable-line
    end
  end
end

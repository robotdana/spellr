# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/spellr/prune'

RSpec.describe Spellr::Prune do
  describe '.run' do
    before do
      stub_config(output: Spellr::OutputStubbed.new)

      with_temp_dir
      english_wordlist
      ruby_wordlist
    end

    let(:english_wordlist) do
      stub_fs_file('.spellr_wordlists/english.txt', <<~FILE)
        entrya
        entryb
        entryc
        entryd
        entrye
      FILE
    end

    let(:ruby_wordlist) do
      stub_fs_file('.spellr_wordlists/ruby.txt', <<~FILE)
        entryc
        entryd
      FILE
    end

    context 'with some unnecessary words' do
      before do
        stub_fs_file('checkable_file.rb', 'entrya entryc')
        stub_fs_file('checkable_file.txt', 'entryb')
      end

      it 'removes unnecessary words, most general file first.' do
        described_class.run

        expect(english_wordlist.read).to eq <<~FILE
          entrya
          entryb
        FILE

        expect(ruby_wordlist.read).to eq <<~FILE
          entryc
        FILE
      end
    end

    context 'with only unnecessary words' do
      before do
        stub_fs_file('checkable_file.rb', 'entrya')
        stub_fs_file('checkable_file.txt', 'entryb')
      end

      it 'removes unnecessary words, most general file first, deletes empty files' do
        described_class.run

        expect(english_wordlist.read).to eq <<~FILE
          entrya
          entryb
        FILE

        expect(ruby_wordlist).not_to exist
      end
    end

    context 'with only necessary words' do
      before do
        stub_fs_file('checkable_file.rb', 'entrya entryc entryd')
        stub_fs_file('checkable_file.txt', 'entryb')
      end

      it 'removes unnecessary words, most general file first.' do
        described_class.run

        expect(english_wordlist.read).to eq <<~FILE
          entrya
          entryb
        FILE

        expect(ruby_wordlist.read).to eq <<~FILE
          entryc
          entryd
        FILE
      end
    end
  end
end

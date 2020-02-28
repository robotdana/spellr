# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/spellr/output_stubbed'

RSpec.describe Spellr::OutputStubbed do
  describe 'exit_code' do
    it 'has a default exit code' do
      expect(subject.exit_code).to be 0
    end

    it 'can set the exit code' do
      subject.exit_code = 1
      expect(subject.exit_code).to be 1
    end

    it 'can only make the exit code worse' do
      subject.exit_code = 0
      expect(subject.exit_code).to be 0
      subject.exit_code = 1
      expect(subject.exit_code).to be 1
      subject.exit_code = 0
      expect(subject.exit_code).to be 1
    end
  end

  describe 'stdin' do
    it "doesn't point to the real stdin" do
      expect(subject.stdin).not_to eq $stdin
    end
  end

  describe 'stdout' do
    it "doesn't points to the real stdout" do
      expect(subject.stdout).not_to eq $stdout
    end

    it 'might not set the stdout yet' do
      expect(subject).not_to be_stdout
      subject.stdout
      expect(subject).to be_stdout
    end
  end

  describe 'stderr' do
    it "doesn't points to the real stderr" do
      expect(subject.stderr).not_to eq $stderr
    end

    it 'might not set the stderr yet' do
      expect(subject).not_to be_stderr
      subject.stderr
      expect(subject).to be_stderr
    end
  end

  describe 'increment' do
    it 'can count anything' do
      subject.increment(:socks)
      subject.increment(:socks)
      subject.increment(:shoes)
      expect(subject.counts).to eq(socks: 2, shoes: 1)
    end
  end

  describe 'marshal_dump' do
    it 'can marshall nothing if nothing has happened' do
      expect(Marshal.load(Marshal.dump(subject)).instance_variables).to be_empty
    end

    it 'can marshall everything if everything has happened' do
      subject.stdin.puts 'I AM STDIN'
      subject.puts 'I AM STDOUT'
      subject.warn 'I AM STDERR'
      subject.increment(:toast)
      subject.increment(:jam)
      subject.increment(:toast)
      subject.exit_code = 1
      restored = Marshal.load(Marshal.dump(subject))
      expect(restored.stdin.pos).to eq 11
      expect(restored.stdout.pos).to eq 12
      expect(restored.stderr.pos).to eq 12
      expect(restored.stdin.read).to eq ''
      expect(restored.stdout.read).to eq ''
      expect(restored.stderr.read).to eq ''
      restored.stdin.rewind
      restored.stdout.rewind
      restored.stderr.rewind
      expect(restored.stdin.read).to eq "I AM STDIN\n"
      expect(restored.stdout.read).to eq "I AM STDOUT\n"
      expect(restored.stderr.read).to eq "I AM STDERR\n"
      expect(restored.counts[:toast]).to eq 2
      expect(restored.counts[:jam]).to eq 1
      expect(restored.exit_code).to eq 1
    end
  end

  describe '<<' do
    let(:other) { described_class.new }

    it 'can merge nothing with nothing' do
      subject << other

      expect(subject.stderr.string).to be_empty
      expect(subject.stdout.string).to be_empty
      expect(subject.stdin.string).to be_empty
      expect(subject.exit_code).to be 0
      expect(subject.counts).to be_empty
    end

    it 'can merge nothing with something' do
      subject.exit_code = 2
      subject.stdin.puts 'hi'
      subject.puts 'look at this'
      subject.warn "don't look at this"
      subject.increment(:cats)
      subject.increment(:dogs)
      subject.increment(:cats)

      subject << other

      expect(subject.stderr.string).to eq "don't look at this\n"
      expect(subject.stdout.string).to eq "look at this\n"
      expect(subject.stdin.string).to eq "hi\n"
      expect(subject.exit_code).to be 2
      expect(subject.counts).to eq(cats: 2, dogs: 1)
    end

    it 'can merge something with nothing' do
      other.exit_code = 2
      other.stdin.puts 'hi'
      other.puts 'look at this'
      other.warn "don't look at this"
      other.increment(:cats)
      other.increment(:dogs)
      other.increment(:cats)

      subject << other

      expect(subject.stderr.string).to eq "don't look at this\n"
      expect(subject.stdout.string).to eq "look at this\n"
      expect(subject.stdin.string).to eq '' # stdin is intentionally not merged
      expect(subject.exit_code).to be 2
      expect(subject.counts).to eq(cats: 2, dogs: 1)
    end

    it 'can merge something with something' do
      subject.exit_code = 2
      subject.stdin.puts 'hi'
      subject.puts 'look at this'
      subject.warn "don't look at this"
      subject.increment(:cats)
      subject.increment(:dogs)
      subject.increment(:cats)

      other.exit_code = 0
      other.stdin.puts 'there'
      other.puts 'now look at this'
      other.warn 'never look at this'
      other.increment(:cats)
      other.increment(:mice)
      other.increment(:mice)

      subject << other

      expect(subject.stderr.string).to eq "don't look at this\nnever look at this\n"
      expect(subject.stdout.string).to eq "look at this\nnow look at this\n"
      expect(subject.stdin.string).to eq "hi\n" # stdin is intentionally not merged
      expect(subject.exit_code).to be 2
      expect(subject.counts).to eq(cats: 3, dogs: 1, mice: 2)
    end
  end
end

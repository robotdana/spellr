# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/spellr/output'

RSpec.describe Spellr::Output do
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
    it 'points to the real stdin' do
      expect(subject.stdin).to eq $stdin
    end
  end

  describe 'stdout' do
    it 'points to the real stdout' do
      expect(subject.stdout).to eq $stdout
    end

    it 'might not set the stdout yet' do
      expect(subject).not_to be_stdout
      subject.stdout
      expect(subject).to be_stdout
    end
  end

  describe 'stderr' do
    it 'points to the real stderr' do
      expect(subject.stderr).to eq $stderr
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
end

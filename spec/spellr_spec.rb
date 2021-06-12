# frozen_string_literal: true

require_relative '../lib/spellr/version'

RSpec.describe Spellr do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be nil
  end

  describe 'pwd' do
    it 'is $PWD' do
      expect(described_class.pwd.to_s).to eq ENV['PWD']
    end

    it 'is Pathname' do
      expect(described_class.pwd).to be_a(Pathname)
    end
  end

  describe 'pwd_s' do
    it 'is $PWD' do
      expect(described_class.pwd_s).to eq ENV['PWD']
    end

    it 'is a String' do
      expect(described_class.pwd_s.class).to be(String)
    end
  end
end

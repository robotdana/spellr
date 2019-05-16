# frozen_string_literal: true

require_relative '../lib/spellr/version'

RSpec.describe Spellr::VERSION do
  it 'has a version number' do
    expect(described_class).not_to be nil
  end
end

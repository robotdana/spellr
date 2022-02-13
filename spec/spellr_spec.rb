# frozen_string_literal: true

require_relative '../lib/spellr/version'

RSpec.describe Spellr do
  changelog = ::File.read(::File.expand_path('../CHANGELOG.md', __dir__))
  changelog_version = changelog.match(/^# v([\d.]+)$/)&.captures&.first

  it "has the version number: #{changelog_version}, matching the changelog" do
    expect(described_class::VERSION).to eq changelog_version
  end
end

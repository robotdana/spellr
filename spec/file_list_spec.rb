# frozen_string_literal: true

require 'pathname'
require_relative '../lib/spellr/file_list'

RSpec::Matchers.define :match_relative_paths do |*expected|
  match do |actual|
    @actual = actual.map { |a| Pathname.new(a.to_s).relative_path_from(Spellr.pwd).to_s }
    expect(@actual).to match_array(expected)
  end

  diffable
end

RSpec.describe Spellr::FileList do
  before do
    with_temp_dir

    stub_fs_file_list %w{
      foo.rb
      foo/bar.txt
      spec/foo_spec.rb
    }
  end

  describe '#each' do
    it 'can be given a block' do
      paths = []

      described_class.new.each do |path|
        paths << path
      end

      expect(paths).to match_relative_paths(
        'foo.rb',
        'foo/bar.txt',
        'spec/foo_spec.rb'
      )
    end

    it 'can be given random enumerable method' do
      object = described_class.new.each_with_object([]) do |path, paths|
        paths << path
      end

      expect(object).to match_relative_paths(
        'foo.rb',
        'foo/bar.txt',
        'spec/foo_spec.rb'
      )
    end

    it 'can return an enumerator' do
      expect(described_class.new.each).to be_a Enumerator

      expect(described_class.new.each.to_a).to match_relative_paths(
        'foo.rb',
        'foo/bar.txt',
        'spec/foo_spec.rb'
      )
    end

    it 'yields ::Spellr::File objects to the block argument' do
      # rubocop:disable RSpec/IteratedExpectation
      # I'm directly testing each and blocks here
      described_class.new.each do |file|
        expect(file).to be_a ::Spellr::File
      end
      # rubocop:enable RSpec/IteratedExpectation
    end

    it 'returns ::Spellr::File objects when an enumerator' do
      expect(described_class.new.each.to_a).to all(be_a ::Spellr::File)
    end
  end

  it 'globs everything' do
    expect(described_class.new.to_a).to match_relative_paths(
      'foo.rb',
      'foo/bar.txt',
      'spec/foo_spec.rb'
    )
  end

  it 'globs extensions' do
    expect(described_class.new('*.rb').to_a).to match_relative_paths(
      'foo.rb',
      'spec/foo_spec.rb'
    )
  end

  it 'globs partial filenames' do
    expect(described_class.new('*_spec.rb').to_a).to match_relative_paths(
      'spec/foo_spec.rb'
    )
  end

  it 'can respect absolute paths' do
    expect(described_class.new(Spellr.pwd.join('foo.rb').to_s).to_a).to match_relative_paths(
      'foo.rb'
    )
  end

  context 'with a gitignore' do
    before do
      stub_fs_file('.gitignore', <<~BODY)
        foo*
        !spec/foo*
      BODY
    end

    it 'ignores gitignore files' do
      expect(described_class.new.to_a).to match_relative_paths(
        '.gitignore',
        'spec/foo_spec.rb'
      )
    end
  end

  context 'with excluded files' do
    before { stub_config(excludes: ['foo.rb', '*.txt']) }

    it 'ignores excluded files' do
      expect(described_class.new.to_a).to match_relative_paths(
        'spec/foo_spec.rb'
      )
    end
  end

  context 'with excluded files and suppressing those files' do
    before { stub_config(excludes: ['foo.rb', '*.txt'], suppress_file_rules: true) }

    it 'ignores excluded files' do
      expect(described_class.new.to_a).to match_relative_paths(
        'foo.rb',
        'foo/bar.txt',
        'spec/foo_spec.rb'
      )
    end
  end

  context 'with suppressing default exclusions files' do
    before { stub_config(suppress_file_rules: true) }

    it 'ignores excluded files' do
      stub_fs_file '.git/COMMIT_EDITMSG'

      expect(described_class.new('.git/COMMIT_EDITMSG').to_a).to match_relative_paths(
        '.git/COMMIT_EDITMSG'
      )
    end
  end

  context 'without suppressing default exclusions files' do
    before { stub_config(suppress_file_rules: false) }

    it 'ignores excluded files' do
      stub_fs_file '.git/COMMIT_EDITMSG'

      expect(described_class.new('.git/COMMIT_EDITMSG').to_a).not_to match_relative_paths(
        '.git/COMMIT_EDITMSG'
      )
    end
  end
end

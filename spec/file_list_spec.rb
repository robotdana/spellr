# frozen_string_literal: true

RSpec::Matchers.define :match_relative_paths do |*expected|
  match do |actual|
    @actual = actual.map { |a| Pathname.new(a.to_s).relative_path_from(Pathname.pwd).to_s }
    expect(@actual).to match_array(expected)
  end

  diffable
end

RSpec.describe Spellr::FileList do
  around do |example|
    with_temp_dir { example.run }
  end

  before do
    stub_fs_file_list %w{
      foo.rb
      foo/bar.txt
      spec/foo_spec.rb
    }
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

  xit 'can respect absolute paths' do
    expect(described_class.new(Pathname.pwd.join('foo.rb').to_s).to_a).to match_relative_paths(
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
    before { stub_config(ignored: ['foo.rb', '*.txt']) }

    it 'ignores excluded files' do
      expect(described_class.new.to_a).to match_relative_paths(
        'spec/foo_spec.rb'
      )
    end
  end
end

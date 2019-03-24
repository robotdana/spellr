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
    expect(Spellr::FileList.new.files).to match_relative_paths(
      'foo.rb',
      'foo/bar.txt',
      'spec/foo_spec.rb'
    )
  end

  it 'globs extensions' do
    expect(Spellr::FileList.new('*.rb').files).to match_relative_paths(
      'foo.rb',
      'spec/foo_spec.rb'
    )
  end

  it 'globs partial filenames' do
    expect(Spellr::FileList.new('*_spec.rb').files).to match_relative_paths(
      'spec/foo_spec.rb'
    )
  end

  it "can respect absolute paths" do
    expect(Spellr::FileList.new(Pathname.pwd.join('foo.rb').to_s).files).to match_relative_paths(
      'foo.rb'
    )
  end

  it "ignores gitignore files" do
    stub_fs_file('.gitignore', <<~BODY)
      foo*
      !spec/foo*
    BODY
    expect(Spellr::FileList.new.files).to match_relative_paths(
      '.gitignore',
      'spec/foo_spec.rb'
    )
  end

  it "ignores excluded files" do
    stub_config(exclusions: ["foo.rb", "*.txt"])

    expect(Spellr::FileList.new.files).to match_relative_paths(
      'spec/foo_spec.rb'
    )
  end
end

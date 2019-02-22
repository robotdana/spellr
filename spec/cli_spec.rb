RSpec.describe 'command line', type: :cli do
  describe '--help' do
    it 'returns the help' do
      run 'spellr --help'
      expect(exitstatus).to be 0
      expect(stderr).to be_empty
      expect(stdout).to eq [
        'Usage: spellr [options]',
        '        --list                       List files to be spellchecked',
        '    -i, --interactive                Runs the spell check interactively',
        '    -v, --version                    Returns the current version',
        '    -h, --help                       Shows this message'
      ]
    end
  end

  describe '--version' do
    it 'returns the version when given --version' do
      run 'spellr --version'
      expect(exitstatus).to be 0
      expect(stderr).to be_empty
      expect(stdout).to eq Spellr::VERSION
    end

    it 'returns the version when given -v' do
      run 'spellr -v'
      expect(exitstatus).to be 0
      expect(stderr).to be_empty
      expect(stdout).to eq Spellr::VERSION
    end

    it 'returns the version and exits when given additional options' do
      run 'spellr --version --interactive'
      expect(exitstatus).to be 0
      expect(stderr).to be_empty
      expect(stdout).to eq Spellr::VERSION
    end

    it 'returns the version and exits when given additional short options' do
      run 'spellr -vi'
      expect(exitstatus).to be 0
      expect(stderr).to be_empty
      expect(stdout).to eq Spellr::VERSION
    end

    it 'returns the version when given both short and long options' do
      run 'spellr -v --version'
      expect(exitstatus).to be 0
      expect(stderr).to be_empty
      expect(stdout).to eq Spellr::VERSION
    end
  end

  context 'with some files' do
    file 'lib/bar.rb'
    file 'foo.md'

    it 'returns the list of files when given no arguments' do
      run 'spellr --list'
      expect(without_temp_path(stdout)).to match_array [
        'lib/bar.rb',
        'foo.md'
      ]
    end
  end

  context 'with no arguments' do
    it 'does not return the version' do
      run 'spellr'
      expect(stdout).to_not include Spellr::VERSION
    end
  end
end

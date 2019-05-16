# frozen_string_literal: true

require_relative '../lib/spellr/version'

RSpec.describe 'command line', type: :cli do
  describe '--help' do
    it 'returns the help' do # rubocop:disable RSpec/ExampleLength
      run 'spellr --help'
      expect(exitstatus).to be 0
      expect(stderr).to be_empty
      expect(stdout).to eq <<~HELP.split("\n")
        Usage: spellr [options]
            -w, --wordlist                   Outputs errors in wordlist format
            -q, --quiet                      Silences all output
            -i, --interactive                Runs the spell check interactively
            -c, --config FILENAME            Path to the config file
            -l, --list                       List files to be spellchecked
            -v, --version                    Returns the current version
            -h, --help                       Shows this message
      HELP
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
      expect(stdout).to match_array [
        'lib/bar.rb',
        'foo.md'
      ]
    end

    it 'returns the list of files when given an extensions to subset' do
      run 'spellr --list \*.rb'
      expect(stdout).to eq 'lib/bar.rb'
    end

    it 'returns the list of files when given a dir to subset' do
      run 'spellr --list lib/*'
      expect(stdout).to eq 'lib/bar.rb'
    end
  end

  context 'with no arguments' do
    it 'does not return the version' do
      run 'spellr'
      expect(stdout).not_to include Spellr::VERSION
    end
  end
end

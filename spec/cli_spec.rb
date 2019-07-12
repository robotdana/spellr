# frozen_string_literal: true

require_relative '../lib/spellr/version'
RSpec.describe 'command line', type: :cli do
  describe '--help' do
    it 'returns the help' do # rubocop:disable RSpec/ExampleLength
      run('spellr --help')

      expect(exitstatus).to eq 0
      expect(stderr).to be_empty
      expect(stdout).to eq <<~HELP.chomp
        Usage: spellr [options] [files]

            -w, --wordlist                   Outputs errors in wordlist format
            -q, --quiet                      Silences output
            -i, --interactive                Runs the spell check interactively

            -d, --dry-run                    List files to be checked

            -c, --config FILENAME            Path to the config file (default ./.spellr.yml)
            -v, --version                    Returns the current version
            -h, --help                       Shows this message

        Usage: spellr fetch [options] WORDLIST [wordlist options]
        Available wordlists: ["english", "ruby"]

            -o, --output=OUTPUT              Outputs the fetched wordlist to OUTPUT/WORDLIST.txt
            -h, --help                       Shows help for fetch
      HELP
    end
  end

  describe '--version' do
    it 'returns the version when given --version' do
      run('spellr --version')

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout).to eq Spellr::VERSION
    end

    it 'returns the version when given -v' do
      run('spellr -v')

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout).to eq Spellr::VERSION
    end

    it 'returns the version and exits when given additional options' do
      run('spellr --version --interactive')

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout).to eq Spellr::VERSION
    end

    it 'returns the version and exits when given additional short options' do
      run('spellr -vi')

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout).to eq Spellr::VERSION
    end

    it 'returns the version when given both short and long options' do
      run('spellr -v --version')

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout).to eq Spellr::VERSION
    end
  end

  context 'with some files' do
    around do |example|
      with_temp_dir { example.run }
    end

    before do
      stub_fs_file_list %w{
        foo.md
        lib/bar.rb
      }
    end

    it 'returns the list of files when given no further arguments' do # rubocop:disable RSpec/ExampleLength
      run('spellr --dry-run')

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout.split("\n")).to match_array [
        'lib/bar.rb',
        'foo.md'
      ]
    end

    it 'returns the list of files when given an extensions to subset' do
      run('spellr --dry-run \*.rb')

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout).to eq 'lib/bar.rb'
    end

    it 'returns the list of files when given a dir to subset' do
      run('spellr --dry-run lib/\*')

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout).to eq 'lib/bar.rb'
    end
  end

  context 'with files with errors' do
    # otherwise the default config fetches them
    let(:config) { Pathname.new(__dir__).join('support', '.spellr.yml') }

    around do |example|
      with_temp_dir { example.run }
    end

    before do
      stub_fs_file '.spellr_wordlists/english.txt', <<~FILE
        ipsum
        lorem
      FILE

      stub_fs_file 'check.txt', <<~FILE
        lorem ipsum dolor

        sit amet
      FILE
    end

    describe '--wordlist' do
      it 'returns the list of unmached words' do # rubocop:disable RSpec/ExampleLength
        run "spellr --wordlist -c #{config}"

        expect(stderr).to be_empty
        expect(exitstatus).to eq 1
        expect(stdout).to eq <<~WORDS.chomp
          amet
          dolor
          sit
        WORDS
      end
    end

    describe 'spellr' do
      it 'returns the list of unmached words and their locations' do # rubocop:disable RSpec/ExampleLength
        run "spellr -c #{config}"

        expect(stderr).to be_empty
        expect(exitstatus).to eq 1
        expect(stdout).to eq <<~WORDS.chomp
          \033[36mcheck.txt:1:12\033[0m lorem ipsum \033[1;31mdolor\033[0m
          \033[36mcheck.txt:3:0\033[0m \033[1;31msit\033[0m amet
          \033[36mcheck.txt:3:4\033[0m sit \033[1;31mamet\033[0m

          1 file checked
          3 errors found
        WORDS
      end
    end
  end

  context 'when in an empty dir' do
    # otherwise the default config fetches them
    let(:config) { Pathname.new(__dir__).join('support', '.spellr.yml') }

    around do |example|
      with_temp_dir { example.run }
    end

    it 'does not return the version' do # rubocop:disable RSpec/ExampleLength
      run("spellr -c #{config}")

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout).to eq <<~STDOUT.chomp

        0 files checked
        0 errors found
      STDOUT
    end
  end
end

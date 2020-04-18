# frozen_string_literal: true

require_relative '../lib/spellr/version'
RSpec.describe 'command line', type: :cli do
  describe '--help' do
    it 'returns the help' do
      run_exe('spellr --help')

      expect(stdout.chomp).to eq <<~HELP.chomp
        Usage: spellr [options] [files]

            -w, --wordlist                   Outputs errors in wordlist format
            -q, --quiet                      Silences output
            -i, --interactive                Runs the spell check interactively

                --[no-]parallel              Run in parallel or not, default --parallel
            -d, --dry-run                    List files to be checked

            -c, --config FILENAME            Path to the config file (default ./.spellr.yml)
            -v, --version                    Returns the current version
            -h, --help                       Shows this message
      HELP
      expect(exitstatus).to eq 0
      expect(stderr).to be_empty
    end
  end

  describe 'bin/generate' do
    around do |example|
      with_temp_dir(example)
    end

    describe 'bin/generate/ruby' do
      it 'runs' do
        # skip stdlib because otherwise this test takes over a minute
        run_bin 'generate/ruby'

        expect(stderr).to be_empty
        # expect(stdout).to be_empty
        expect(exitstatus).to eq 0
        expect(Pathname.pwd.join('wordlists/ruby.txt')).to exist

        run_bin 'generate/ruby'

        expect(stderr).to be_empty
        # expect(stdout).to be_empty
        expect(exitstatus).to eq 0
        expect(Pathname.pwd.join('wordlists/ruby.txt')).to exist
      end
    end

    describe 'bin/possible_key_data/train' do
      it 'runs' do
        stub_fs_file 'keys.txt', <<~TXT
          zXNm1F
          zXNm1F
          zXNm1F
          zXNm1F
        TXT

        stub_fs_file 'false_positives.txt', <<~TXT
          this1that2
          this1that2
          this1that2
          this1that2
        TXT

        run_bin 'possible_key_data/train'

        expect(stderr).to be_empty
        expect(stdout).to be_empty
        expect(exitstatus).to eq 0
        expect(Pathname.pwd.join('data.yml')).to exist
      end
    end

    describe 'bin/generate/css' do
      it 'runs' do
        run_bin 'generate/css'

        expect(stderr).to be_empty
        expect(stdout).to be_empty
        expect(exitstatus).to eq 0

        expect(Pathname.pwd.join('wordlists/css.txt')).to exist
        expect(Pathname.pwd.join('wordlists/css.LICENSE.md')).to exist
      end
    end

    describe 'bin/generate/html' do
      it 'runs' do
        run_bin 'generate/html'

        expect(stderr).to be_empty
        expect(stdout).to be_empty
        expect(exitstatus).to eq 0
        expect(Pathname.pwd.join('wordlists/html.txt')).to exist
        expect(Pathname.pwd.join('wordlists/html.LICENSE.md')).to exist
      end
    end

    describe 'bin/generate/english' do
      it 'runs' do
        run_bin 'generate/english'

        expect(stderr).to be_empty
        expect(stdout).to be_empty
        expect(exitstatus).to eq 0
        expect(Pathname.pwd.join('wordlists/english.txt')).to exist
        expect(Pathname.pwd.join('wordlists/english.LICENSE.txt')).to exist
        expect(Pathname.pwd.join('wordlists/english/US.txt')).to exist
        expect(Pathname.pwd.join('wordlists/english/US.LICENSE.txt')).to exist
        expect(Pathname.pwd.join('wordlists/english/GB.txt')).to exist
        expect(Pathname.pwd.join('wordlists/english/GB.LICENSE.txt')).to exist
      end
    end
  end

  describe 'rake' do
    around do |example|
      with_temp_dir(example)
    end

    context 'with a rake task with no arguments' do
      before do
        stub_fs_file 'Rakefile', <<~RUBY
          require '#{__dir__}/../lib/spellr/rake_task'

          Spellr::RakeTask.generate_task
          task default: :spellr
        RUBY
      end

      it 'shows in the task list' do
        run_rake('-T')

        expect(stderr).to be_empty
        expect(exitstatus).to eq 0
        expect(stdout).to eq <<~STDOUT.chomp
          rake spellr[*args]  # Run spellr
        STDOUT
      end

      it 'can be run with no arguments' do
        run_rake('spellr')
        expect(stderr).to be_empty
        expect(exitstatus).to eq 0
        expect(stdout).to eq <<~STDOUT.chomp
          \e[2mspellr \e[0m

          1 file checked
          0 errors found
        STDOUT
      end

      it 'can be run with arguments' do
        run_rake('spellr[--quiet]')
        expect(stderr).to be_empty
        expect(exitstatus).to eq 0
        expect(stdout).to eq <<~STDOUT.chomp
          \e[2mspellr --quiet\e[0m
        STDOUT
      end

      it 'can be run with the default task' do
        run_rake
        expect(stderr).to be_empty
        expect(exitstatus).to eq 0
        expect(stdout).to eq <<~STDOUT.chomp
          \e[2mspellr \e[0m

          1 file checked
          0 errors found
        STDOUT
      end

      it 'can run a with a spelling error' do
        stub_fs_file 'foo.txt', 'notaword'

        run_rake

        expect(stderr).to be_empty
        expect(exitstatus).to eq 1
        expect(stdout).to eq <<~STDOUT.chomp
          \e[2mspellr \e[0m
          #{aqua 'foo.txt:1:0'} #{red 'notaword'}

          2 files checked
          1 error found
        STDOUT
      end
    end

    context 'with a rake task with default arguments' do
      before do
        stub_fs_file 'Rakefile', <<~RUBY
          require '#{__dir__}/../lib/spellr/rake_task'

          Spellr::RakeTask.generate_task(:spellr_quiet, '--quiet')
          task default: :spellr_quiet
        RUBY
      end

      it 'shows in the task list' do
        run_rake('-T')
        expect(stderr).to be_empty
        expect(exitstatus).to eq 0
        expect(stdout).to eq <<~STDOUT.chomp
          rake spellr_quiet[*args]  # Run spellr (default args: --quiet)
        STDOUT
      end

      it 'can be run with the default arguments' do
        run_rake('spellr_quiet')
        expect(stderr).to be_empty
        expect(exitstatus).to eq 0
        expect(stdout).to eq <<~STDOUT.chomp
          \e[2mspellr --quiet\e[0m
        STDOUT
      end

      it 'can be run with replacement arguments' do
        run_rake('spellr_quiet[--no-parallel]')
        expect(stderr).to be_empty
        expect(exitstatus).to eq 0
        expect(stdout).to eq <<~STDOUT.chomp
          \e[2mspellr --no-parallel\e[0m

          1 file checked
          0 errors found
        STDOUT
      end

      it 'can be run as the default task' do
        run_rake
        expect(stderr).to be_empty
        expect(exitstatus).to eq 0
        expect(stdout).to eq <<~STDOUT.chomp
          \e[2mspellr --quiet\e[0m
        STDOUT
      end

      it 'can run with a spelling error' do
        stub_fs_file 'foo.txt', 'notaword'

        run_rake

        expect(stderr).to be_empty
        expect(exitstatus).to eq 1
        expect(stdout).to eq <<~STDOUT.chomp
          \e[2mspellr --quiet\e[0m
        STDOUT
      end
    end
  end

  describe '--version' do
    it 'returns the version when given --version' do
      run_exe('spellr --version')

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout).to eq Spellr::VERSION
    end

    it 'returns the version when given -v' do
      run_exe('spellr -v')

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout).to eq Spellr::VERSION
    end

    it 'returns the version and exits when given additional options' do
      run_exe('spellr --version --interactive')

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout).to eq Spellr::VERSION
    end

    it 'returns the version and exits when given additional short options' do
      run_exe('spellr -vi')

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout).to eq Spellr::VERSION
    end

    it 'returns the version when given both short and long options' do
      run_exe('spellr -v --version')

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout).to eq Spellr::VERSION
    end
  end

  describe 'combining --parallel and --interactive' do
    it 'complains when --interactive then --parallel' do
      run_exe('spellr --interactive --parallel') do |_stdout, _stdin, _pid, stderr|
        expect(stderr).to print <<~STDERR.chomp
          #{red('CLI error: --interactive is incompatible with --parallel')}
        STDERR
      end
    end

    it 'complains when --parallel then --interactive' do
      run_exe('spellr --parallel --interactive') do |_stdout, _stdin, _pid, stderr|
        expect(stderr).to print <<~STDERR.chomp
          #{red('CLI error: --interactive is incompatible with --parallel')}
        STDERR
      end
    end
  end

  describe '--interactive in a non tty' do
    it 'complains' do
      run_exe('spellr --interactive')

      expect(stderr).to eq <<~STDERR.chomp
        #{red('CLI error: --interactive is unavailable in a non-interactive terminal')}
      STDERR
    end
  end

  describe 'config validations' do
    around do |example|
      with_temp_dir(example)
    end

    it 'complains with conflicting implicit keys' do
      stub_fs_file '.spellr.yml', <<~YML
        languages:
          ruby: {}
          russian: {}
      YML

      run_exe("spellr --config=#{Dir.pwd}/.spellr.yml")

      expect(stderr).to eq(
        red(
          'Config error: ruby & russian share the same language key (r). '\
          'Please define one to be different with `key:`'
        )
      )
    end

    it 'complains with conflicting explicit keys' do
      stub_fs_file '.spellr.yml', <<~YML
        languages:
          english: {}
          spanish:
            key: e
      YML

      run_exe("spellr --config=#{Dir.pwd}/.spellr.yml")

      expect(stderr).to eq(
        red(
          'Config error: english & spanish share the same language key (e). '\
          'Please define one to be different with `key:`'
        )
      )
    end

    it 'complains with multicharacter keys' do
      stub_fs_file '.spellr.yml', <<~YML
        languages:
          english:
            key: en
          ruby:
            key: ru
      YML

      run_exe("spellr --config=#{Dir.pwd}/.spellr.yml")

      expect(stderr).to eq red(<<~STDERR.chomp)
        Config error: english defines a key that is too long (en). Please change it to be a single character
        Config error: ruby defines a key that is too long (ru). Please change it to be a single character
      STDERR
    end

    it 'complains with a missing specified config' do
      run_exe("spellr --config=#{Dir.pwd}/my-spellr.yml")

      expect(stderr).to eq red("Config error: #{Dir.pwd}/my-spellr.yml not found or not readable")
    end
  end

  context 'with ruby files without errors' do
    around do |example|
      with_temp_dir(example)
    end

    before do
      stub_fs_file 'test.rb', <<~RUBY
        "string".casecmp "STRING"
      RUBY

      stub_fs_file 'test_env_ruby', <<~RUBY
        #!/usr/bin/env ruby
        "string".casecmp "STRING"
      RUBY

      stub_fs_file 'test_bin_ruby', <<~RUBY
        #!/bin/ruby
        "string".casecmp "STRING"
      RUBY

      stub_fs_file 'test_control.txt', <<~RUBY
        "string".casecmp "STRING"
      RUBY

      stub_fs_file 'test_control_no_ext', <<~RUBY
        "string".casecmp "STRING"
      RUBY

      stub_fs_file 'empty_no_ext', <<~RUBY
      RUBY
    end

    it 'allows the ruby files to say casecmp but not the txt file' do
      run_exe('spellr --no-parallel') # parallel was making this test failure order random

      expect(stderr).to be_empty
      expect(exitstatus).to eq 1
      expect(stdout).to eq <<~WORDS.chomp
        #{aqua 'test_control.txt:1:9'} "string".#{red 'casecmp'} "STRING"
        #{aqua 'test_control_no_ext:1:9'} "string".#{red 'casecmp'} "STRING"

        6 files checked
        2 errors found
      WORDS
    end
  end

  context 'with some files' do
    around do |example|
      with_temp_dir(example)
    end

    before do
      stub_fs_file_list %w{
        foo.md
        lib/bar.rb
      }
    end

    it 'returns the list of files when given no further arguments' do
      run_exe('spellr --dry-run')

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout.split("\n")).to contain_exactly(
        'lib/bar.rb',
        'foo.md'
      )
    end

    it 'can combine dry-run with no-parallel (by not being parallel in the firsts place)' do
      run_exe('spellr --dry-run --no-parallel')

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout.split("\n")).to contain_exactly(
        'lib/bar.rb',
        'foo.md'
      )
    end

    it 'can combine dry-run with parallel (by ignoring --parallel)' do
      run_exe('spellr --dry-run --parallel')

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout.split("\n")).to contain_exactly(
        'lib/bar.rb',
        'foo.md'
      )
    end

    it 'returns the list of files when given an extensions to subset' do
      run_exe('spellr --dry-run \*.rb')

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout).to eq 'lib/bar.rb'
    end

    it 'returns the list of files when given a dir to subset' do
      run_exe('spellr --dry-run lib/')

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout).to eq 'lib/bar.rb'
    end

    describe '--quiet' do
      it "doesn't output to stdout or stderr but does return the correct exitstatus" do
        run_exe 'spellr --quiet'

        expect(stderr).to be_empty
        expect(exitstatus).to eq 0
        expect(stdout).to be_empty
      end
    end
  end

  context 'with files with errors' do
    around do |example|
      with_temp_dir(example)
    end

    let!(:english_wordlist) do
      stub_fs_file '.spellr_wordlists/english.txt', <<~FILE
        ipsum
        lorem
      FILE
    end

    let!(:check_file) do
      stub_fs_file 'check.txt', <<~FILE
        lorem ipsum dolar

          dolar amet
      FILE
    end

    describe '--quiet' do
      it "doesn't output to stdout or stderr but does return the correct exitstatus" do
        run_exe 'spellr --quiet'

        expect(stderr).to be_empty
        expect(exitstatus).to eq 1
        expect(stdout).to be_empty
      end

      it "doesn't output anything but exitstatus when combined with no-parallel" do
        run_exe 'spellr --quiet --no-parallel'

        expect(stderr).to be_empty
        expect(exitstatus).to eq 1
        expect(stdout).to be_empty
      end

      it "doesn't output anything but exitstatus when combined with parallel" do
        run_exe 'spellr --quiet --parallel'

        expect(stderr).to be_empty
        expect(exitstatus).to eq 1
        expect(stdout).to be_empty
      end
    end

    describe '--wordlist' do
      it 'returns the list of unmatched words' do
        run_exe 'spellr --wordlist'

        expect(stderr).to be_empty
        expect(exitstatus).to eq 1
        expect(stdout).to eq <<~WORDS.chomp
          amet
          dolar
        WORDS
      end

      it 'can be combined with --parallel' do
        run_exe 'spellr --wordlist --parallel'

        expect(stderr).to be_empty
        expect(exitstatus).to eq 1
        expect(stdout).to eq <<~WORDS.chomp
          amet
          dolar
        WORDS
      end

      it 'can be combined with --no-parallel' do
        run_exe 'spellr --wordlist --no-parallel'

        expect(stderr).to be_empty
        expect(exitstatus).to eq 1
        expect(stdout).to eq <<~WORDS.chomp
          amet
          dolar
        WORDS
      end

      it 'can be configured to only care about longer words' do
        stub_fs_file '.spellr.yml', <<~YML
          word_minimum_length: 6
        YML
        run_exe "spellr --wordlist --config=#{Dir.pwd}/.spellr.yml"

        expect(stderr).to be_empty
        expect(stdout).to be_empty
        expect(exitstatus).to eq 0
      end

      it 'returns an error for invalid files' do
        FileUtils.mkdir 'invalid_dir'

        FileUtils.cp("#{__dir__}/support/invalid_file", './invalid_dir')
        run_exe 'spellr --wordlist'

        expect(stderr).to eq <<~WORDS.chomp
          Skipped unreadable file: #{aqua 'invalid_dir/invalid_file'}
        WORDS

        expect(exitstatus).to eq 1
        expect(stdout).to eq <<~WORDS.chomp
          amet
          dolar
        WORDS
      end
    end

    describe 'spellr' do
      it 'returns the list of unmatched words and their locations' do
        run_exe 'spellr'

        expect(stderr).to be_empty
        expect(exitstatus).to eq 1
        expect(stdout).to eq <<~WORDS.chomp
          #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
          #{aqua 'check.txt:3:2'} #{red 'dolar'} amet
          #{aqua 'check.txt:3:8'} dolar #{red 'amet'}

          1 file checked
          3 errors found
        WORDS
      end

      it 'can be run with --no-parallel' do
        run_exe 'spellr --no-parallel'

        expect(stderr).to be_empty
        expect(exitstatus).to eq 1
        expect(stdout).to eq <<~WORDS.chomp
          #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
          #{aqua 'check.txt:3:2'} #{red 'dolar'} amet
          #{aqua 'check.txt:3:8'} dolar #{red 'amet'}

          1 file checked
          3 errors found
        WORDS
      end
    end

    def prompt(key = nil)
      key = key ? bold(key) : ' '
      "[#{bold 'a'}]dd, [#{bold 'r'}]eplace, [#{bold 's'}]kip, [#{bold 'h'}]elp, [^#{bold 'C'}] to exit: [#{key}]" # rubocop:disable Layout/LineLength
    end

    describe '--interactive' do
      it 'returns the first unmatched term and a prompt' do
        run_exe 'spellr -i' do |stdout, _|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt}
          STDOUT
        end
      end

      it 'returns the interactive command help' do
        run_exe 'spellr -i' do |stdout, stdin|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt}
          STDOUT

          stdin.print 'h'

          expect(stdout).to print <<~STDOUT

            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}

            [#{bold 'a'}] Add #{red 'dolar'} to a word list
            [#{bold 'r'}] Replace #{red 'dolar'}
            [#{bold 'R'}] Replace this and all future instances of #{red 'dolar'}
            [#{bold 's'}] Skip #{red 'dolar'}
            [#{bold 'S'}] Skip this and all future instances of #{red 'dolar'}
            [#{bold 'h'}] Show this help
            [ctrl] + [#{bold 'C'}] Exit spellr

            What do you want to do? [ ]
          STDOUT

          stdin.print 's'

          expect(stdout).to print <<~STDOUT

            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}

            [#{bold 'a'}] Add #{red 'dolar'} to a word list
            [#{bold 'r'}] Replace #{red 'dolar'}
            [#{bold 'R'}] Replace this and all future instances of #{red 'dolar'}
            [#{bold 's'}] Skip #{red 'dolar'}
            [#{bold 'S'}] Skip this and all future instances of #{red 'dolar'}
            [#{bold 'h'}] Show this help
            [ctrl] + [#{bold 'C'}] Exit spellr

            What do you want to do? [#{bold 's'}]
            Skipped #{red 'dolar'}
            #{aqua 'check.txt:3:2'} #{red 'dolar'} amet
            #{prompt}
          STDOUT
        end
      end

      it 'exits when ctrl C' do
        run_exe 'spellr -i' do |stdout, stdin, pid|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt}
          STDOUT

          stdin.print "\u0003" # ctrl c

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt '^C'}
          STDOUT

          expect(pid).to have_exitstatus(1)
        end
      end

      it 'ignores up' do
        run_exe 'spellr -i' do |stdout, stdin|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt}
          STDOUT

          stdin.print "\e[1A"

          sleep 0.1

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt}
          STDOUT
        end
      end

      it 'returns the next unmatched term and a prompt after skipping' do
        run_exe 'spellr -i' do |stdout, stdin|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt}
          STDOUT

          stdin.print 's'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 's'}
            Skipped #{red 'dolar'}
            #{aqua 'check.txt:3:2'} #{red 'dolar'} amet
            #{prompt}
          STDOUT

          stdin.print 's'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 's'}
            Skipped #{red 'dolar'}
            #{aqua 'check.txt:3:2'} #{red 'dolar'} amet
            #{prompt 's'}
            Skipped #{red 'dolar'}
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            #{prompt}
          STDOUT

          stdin.print 's'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 's'}
            Skipped #{red 'dolar'}
            #{aqua 'check.txt:3:2'} #{red 'dolar'} amet
            #{prompt 's'}
            Skipped #{red 'dolar'}
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            #{prompt 's'}
            Skipped #{red 'amet'}

            1 file checked
            3 errors found
            3 errors skipped

          STDOUT
        end
      end

      it 'returns the next unmatched term and a prompt after skipping with S' do
        run_exe 'spellr -i' do |stdout, stdin|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt}
          STDOUT

          stdin.print 'S'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'S'}
            Skipped #{red 'dolar'}
            Automatically skipped #{red 'dolar'}
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            #{prompt}
          STDOUT

          stdin.print 'S'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'S'}
            Skipped #{red 'dolar'}
            Automatically skipped #{red 'dolar'}
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            #{prompt 'S'}
            Skipped #{red 'amet'}

            1 file checked
            3 errors found
            3 errors skipped
          STDOUT
        end
      end

      it 'can bail early when trying to add with a' do
        run_exe 'spellr -i' do |stdout, stdin, pid|
          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt}
          STDOUT

          stdin.print 'a'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'a'}

              [#{bold 'e'}] english
              [^#{bold 'C'}] to go back
              Add #{red 'dolar'} to which wordlist? [ ]
          STDOUT

          stdin.print "\u0003" # ctrl c

          expect(stdout).to print <<~STDOUT.chomp






            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt}
          STDOUT

          stdin.print "\u0003" # ctrl c

          expect(stdout).to print <<~STDOUT.chomp






            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt '^C'}
          STDOUT

          expect(pid).to have_exitstatus(1)
        end
      end

      it "asks me again when i chose a language that doesn't exist when adding with a" do
        run_exe 'spellr -i' do |stdout, stdin|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt}
          STDOUT

          stdin.print 'a'

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'a'}

              [#{bold 'e'}] english
              [^#{bold 'C'}] to go back
              Add #{red 'dolar'} to which wordlist? [ ]
          STDOUT

          stdin.print 'x'

          sleep 0.1 # make sure nothing has changed

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'a'}

              [#{bold 'e'}] english
              [^#{bold 'C'}] to go back
              Add #{red 'dolar'} to which wordlist? [ ]
          STDOUT
        end
      end

      it 'returns the next unmatched term and a prompt after adding with a' do
        run_exe 'spellr -i' do |stdout, stdin|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt}
          STDOUT

          stdin.print 'a'

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'a'}

              [#{bold 'e'}] english
              [^#{bold 'C'}] to go back
              Add #{red 'dolar'} to which wordlist? [ ]
          STDOUT

          stdin.print 'e'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'a'}

              [#{bold 'e'}] english
              [^#{bold 'C'}] to go back
              Add #{red 'dolar'} to which wordlist? [#{bold 'e'}]

            Added #{red 'dolar'} to the #{bold 'english'} wordlist
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            #{prompt}
          STDOUT

          expect(english_wordlist.read).to eq <<~FILE
            dolar
            ipsum
            lorem
          FILE

          stdin.print 'a'

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'a'}

              [#{bold 'e'}] english
              [^#{bold 'C'}] to go back
              Add #{red 'dolar'} to which wordlist? [#{bold 'e'}]

            Added #{red 'dolar'} to the #{bold 'english'} wordlist
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            #{prompt 'a'}

              [#{bold 'e'}] english
              [^#{bold 'C'}] to go back
              Add #{red 'amet'} to which wordlist? [ ]
          STDOUT

          stdin.print 'e'

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'a'}

              [#{bold 'e'}] english
              [^#{bold 'C'}] to go back
              Add #{red 'dolar'} to which wordlist? [#{bold 'e'}]

            Added #{red 'dolar'} to the #{bold 'english'} wordlist
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            #{prompt 'a'}

              [#{bold 'e'}] english
              [^#{bold 'C'}] to go back
              Add #{red 'amet'} to which wordlist? [#{bold 'e'}]

            Added #{red 'amet'} to the #{bold 'english'} wordlist

            1 file checked
            2 errors found
            2 words added
          STDOUT

          expect(english_wordlist.read).to eq <<~FILE
            amet
            dolar
            ipsum
            lorem
          FILE
        end
      end

      it 'can add with a to a new wordlist' do
        stub_fs_file '.spellr.yml', <<~YML
          languages:
            lorem: {}
        YML
        run_exe "spellr -i --config=#{Dir.pwd}/.spellr.yml" do |stdout, stdin|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt}
          STDOUT

          stdin.print 'a'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'a'}

              [#{bold 'e'}] english
              [#{bold 'l'}] lorem
              [^#{bold 'C'}] to go back
              Add #{red 'dolar'} to which wordlist? [ ]
          STDOUT

          stdin.print 'l'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'a'}

              [#{bold 'e'}] english
              [#{bold 'l'}] lorem
              [^#{bold 'C'}] to go back
              Add #{red 'dolar'} to which wordlist? [#{bold 'l'}]

            Added #{red 'dolar'} to the #{bold 'lorem'} wordlist
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            #{prompt}
          STDOUT
        end
      end

      it 'can bail early when trying to replace with R' do
        run_exe 'spellr -i' do |stdout, stdin, pid|
          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt}
          STDOUT

          stdin.print 'R'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'R'}

              #{lighten '[^C] to go back'}
              Replace all #{red 'dolar'} with: \e[32mdolar
          STDOUT

          stdin.print "something\u0003" # ctrl c

          expect(stdout).to print <<~STDOUT.chomp




            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt}
          STDOUT

          stdin.print "\u0003" # ctrl c

          expect(pid).to have_exitstatus(1)
        end
      end

      it 'returns the next unmatched term and a prompt after replacing with R' do
        run_exe 'spellr -i' do |stdout, stdin|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt}
          STDOUT

          stdin.print 'R'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'R'}

              #{lighten '[^C] to go back'}
              Replace all #{red 'dolar'} with: \e[32mdolar
          STDOUT

          stdin.print "es\n"

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'R'}

              #{lighten '[^C] to go back'}
              Replace all #{red 'dolar'} with: \e[32mdolares

            \e[0mReplaced all #{red 'dolar'} with #{green 'dolares'}
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolares'}
            #{prompt}
          STDOUT

          expect(check_file.read).to eq <<~FILE
            lorem ipsum dolares

              dolar amet
          FILE

          stdin.print 'a'

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'R'}

              #{lighten '[^C] to go back'}
              Replace all #{red 'dolar'} with: \e[32mdolares

            \e[0mReplaced all #{red 'dolar'} with #{green 'dolares'}
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolares'}
            #{prompt 'a'}

              [#{bold 'e'}] english
              [^#{bold 'C'}] to go back
              Add #{red 'dolares'} to which wordlist? [ ]
          STDOUT

          stdin.print 'e'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'R'}

              #{lighten '[^C] to go back'}
              Replace all #{red 'dolar'} with: \e[32mdolares

            \e[0mReplaced all #{red 'dolar'} with #{green 'dolares'}
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolares'}
            #{prompt 'a'}

              [#{bold 'e'}] english
              [^#{bold 'C'}] to go back
              Add #{red 'dolares'} to which wordlist? [#{bold 'e'}]

            Added #{red 'dolares'} to the #{bold 'english'} wordlist
            Automatically replaced #{red 'dolar'} with #{green 'dolares'}
            #{aqua 'check.txt:3:10'} dolares #{red 'amet'}
            #{prompt}
          STDOUT

          expect(check_file.read).to eq <<~FILE
            lorem ipsum dolares

              dolares amet
          FILE

          expect(english_wordlist.read).to eq <<~FILE
            dolares
            ipsum
            lorem
          FILE

          stdin.print 's'

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'R'}

              #{lighten '[^C] to go back'}
              Replace all #{red 'dolar'} with: \e[32mdolares

            \e[0mReplaced all #{red 'dolar'} with #{green 'dolares'}
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolares'}
            #{prompt 'a'}

              [#{bold 'e'}] english
              [^#{bold 'C'}] to go back
              Add #{red 'dolares'} to which wordlist? [#{bold 'e'}]

            Added #{red 'dolares'} to the #{bold 'english'} wordlist
            Automatically replaced #{red 'dolar'} with #{green 'dolares'}
            #{aqua 'check.txt:3:10'} dolares #{red 'amet'}
            #{prompt 's'}
            Skipped #{red('amet')}

            1 file checked
            4 errors found
            1 error skipped
            2 errors fixed
            1 word added
          STDOUT
        end
      end

      it 'can bail early when trying to replace with r' do
        run_exe 'spellr -i' do |stdout, stdin, pid|
          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt}
          STDOUT

          stdin.print 'r'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'r'}

              #{lighten '[^C] to go back'}
              Replace #{red 'dolar'} with: \e[32mdolar
          STDOUT

          stdin.print "\u0003" # ctrl c

          expect(stdout).to print <<~STDOUT.chomp




            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt}
          STDOUT

          stdin.print "\u0003" # ctrl c

          expect(stdout).to print <<~STDOUT.chomp




            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt '^C'}
          STDOUT

          expect(pid).to have_exitstatus(1)
        end
      end

      it 'disallows replacing with nothing when replacing with r' do
        run_exe 'spellr -i' do |stdout, stdin|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt}
          STDOUT

          stdin.print 'r'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'r'}

              #{lighten '[^C] to go back'}
              Replace #{red 'dolar'} with: \e[32mdolar
          STDOUT

          stdin.print "\b" * 17

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'r'}

              #{lighten '[^C] to go back'}
              Replace #{red 'dolar'} with: \e[32m
          STDOUT

          stdin.puts ''

          # just put the prompt again
          expect(stdout).to print <<~STDOUT.chomp

            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'r'}

              #{lighten '[^C] to go back'}
              Replace #{red 'dolar'} with: \e[32mdolar
          STDOUT
        end
      end

      it 'disallows replacing with the same when replacing with r' do
        run_exe 'spellr -i' do |stdout, stdin|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt}
          STDOUT

          stdin.print 'r'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'r'}

              #{lighten '[^C] to go back'}
              Replace #{red 'dolar'} with: \e[32mdolar
          STDOUT

          stdin.puts ''
          sleep 0.1

          # just put the prompt again
          expect(stdout).to print <<~STDOUT.chomp

            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'r'}

              #{lighten '[^C] to go back'}
              Replace #{red 'dolar'} with: \e[32mdolar
          STDOUT
        end
      end

      it 'returns the next unmatched term and a prompt after replacing with r' do
        run_exe 'spellr -i' do |stdout, stdin|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt}
          STDOUT

          stdin.print 'r'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'r'}

              #{lighten '[^C] to go back'}
              Replace #{red 'dolar'} with: \e[32mdolar
          STDOUT

          stdin.print "es\n"

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'r'}

              #{lighten '[^C] to go back'}
              Replace #{red 'dolar'} with: \e[32mdolares

            \e[0mReplaced #{red('dolar')} with #{green('dolares')}
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolares'}
            #{prompt}
          STDOUT

          expect(check_file.read).to eq <<~FILE
            lorem ipsum dolares

              dolar amet
          FILE

          stdin.print 'a'

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'r'}

              #{lighten '[^C] to go back'}
              Replace #{red 'dolar'} with: \e[32mdolares

            \e[0mReplaced #{red('dolar')} with #{green('dolares')}
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolares'}
            #{prompt 'a'}

              [#{bold 'e'}] english
              [^#{bold 'C'}] to go back
              Add #{red 'dolares'} to which wordlist? [ ]
          STDOUT

          stdin.print 'e'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'r'}

              #{lighten '[^C] to go back'}
              Replace #{red 'dolar'} with: \e[32mdolares

            \e[0mReplaced #{red('dolar')} with #{green('dolares')}
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolares'}
            #{prompt 'a'}

              [#{bold 'e'}] english
              [^#{bold 'C'}] to go back
              Add #{red 'dolares'} to which wordlist? [#{bold 'e'}]

            Added #{red 'dolares'} to the #{bold 'english'} wordlist
            #{aqua 'check.txt:3:2'} #{red 'dolar'} amet
            #{prompt}
          STDOUT

          expect(english_wordlist.read).to eq <<~FILE
            dolares
            ipsum
            lorem
          FILE

          stdin.print 's'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'r'}

              #{lighten '[^C] to go back'}
              Replace #{red 'dolar'} with: \e[32mdolares

            \e[0mReplaced #{red('dolar')} with #{green('dolares')}
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolares'}
            #{prompt 'a'}

              [#{bold 'e'}] english
              [^#{bold 'C'}] to go back
              Add #{red 'dolares'} to which wordlist? [#{bold 'e'}]

            Added #{red 'dolares'} to the #{bold 'english'} wordlist
            #{aqua 'check.txt:3:2'} #{red 'dolar'} amet
            #{prompt 's'}
            Skipped #{red 'dolar'}
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            #{prompt}
          STDOUT

          stdin.print 's'

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{prompt 'r'}

              #{lighten '[^C] to go back'}
              Replace #{red 'dolar'} with: \e[32mdolares

            \e[0mReplaced #{red('dolar')} with #{green('dolares')}
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolares'}
            #{prompt 'a'}

              [#{bold 'e'}] english
              [^#{bold 'C'}] to go back
              Add #{red 'dolares'} to which wordlist? [#{bold 'e'}]

            Added #{red 'dolares'} to the #{bold 'english'} wordlist
            #{aqua 'check.txt:3:2'} #{red 'dolar'} amet
            #{prompt 's'}
            Skipped #{red 'dolar'}
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            #{prompt 's'}
            Skipped #{red 'amet'}

            1 file checked
            4 errors found
            2 errors skipped
            1 error fixed
            1 word added
          STDOUT
        end
      end
    end
  end
end

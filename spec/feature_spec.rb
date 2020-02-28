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

    describe '--interactive' do
      it 'returns the first unmatched term and a prompt' do
        run_exe 'spellr -i' do |stdout, _|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT
        end
      end

      it 'returns the interactive command help' do
        run_exe 'spellr -i' do |stdout, stdin|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.print '?'

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{bold '[r]'} Replace #{red 'dolar'}
            #{bold '[R]'} Replace all future instances of #{red 'dolar'}
            #{bold '[s]'} Skip #{red 'dolar'}
            #{bold '[S]'} Skip all future instances of #{red 'dolar'}
            #{bold '[a]'} Add #{red 'dolar'} to a word list
            #{bold '[e]'} Edit the whole line
            #{bold '[?]'} Show this help
          STDOUT
        end
      end

      it 'exits when ctrl C' do
        run_exe 'spellr -i' do |stdout, stdin, pid|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.puts "\u0003" # ctrl c

          expect(pid).to have_exitstatus(1)
        end
      end

      it 'returns the next unmatched term and a prompt after skipping' do
        run_exe 'spellr -i' do |stdout, stdin|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.print 's'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            Skipped #{red 'dolar'}
            #{aqua 'check.txt:3:2'} #{red 'dolar'} amet
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.print 's'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            Skipped #{red 'dolar'}
            #{aqua 'check.txt:3:2'} #{red 'dolar'} amet
            Skipped #{red 'dolar'}
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.print 's'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            Skipped #{red 'dolar'}
            #{aqua 'check.txt:3:2'} #{red 'dolar'} amet
            Skipped #{red 'dolar'}
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
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
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.print 'S'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            Skipped #{red 'dolar'}
            Automatically skipped #{red 'dolar'}
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.print 'S'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            Skipped #{red 'dolar'}
            Automatically skipped #{red 'dolar'}
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
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
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.print 'a'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            Add #{red 'dolar'} to wordlist:
            [e] english
          STDOUT

          stdin.puts "\u0003" # ctrl c

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            Add #{red 'dolar'} to wordlist:
            [e] english
            ^C again to exit
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.puts "\u0003" # ctrl c

          expect(pid).to have_exitstatus(1)
        end
      end

      it "asks me again when i chose a language that doesn't exist when adding with a" do
        run_exe 'spellr -i' do |stdout, stdin|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.print 'a'

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            Add #{red 'dolar'} to wordlist:
            [e] english
          STDOUT

          stdin.print 'x'

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            Add #{red 'dolar'} to wordlist:
            [e] english
            Add #{red 'dolar'} to wordlist:
            [e] english
          STDOUT
        end
      end

      it 'returns the next unmatched term and a prompt after adding with a' do
        run_exe 'spellr -i' do |stdout, stdin|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.print 'a'

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            Add #{red 'dolar'} to wordlist:
            [e] english
          STDOUT

          stdin.print 'e'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            Add #{red 'dolar'} to wordlist:
            [e] english
            Added #{red 'dolar'} to english wordlist
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          expect(english_wordlist.read).to eq <<~FILE
            dolar
            ipsum
            lorem
          FILE

          stdin.print 'a'

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            Add #{red 'dolar'} to wordlist:
            [e] english
            Added #{red 'dolar'} to english wordlist
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            Add #{red 'amet'} to wordlist:
            [e] english
          STDOUT

          stdin.print 'e'

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            Add #{red 'dolar'} to wordlist:
            [e] english
            Added #{red 'dolar'} to english wordlist
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            Add #{red 'amet'} to wordlist:
            [e] english
            Added #{red 'amet'} to english wordlist

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
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.print 'a'

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            Add #{red 'dolar'} to wordlist:
            [e] english
            [l] lorem
          STDOUT

          stdin.print 'l'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            Add #{red 'dolar'} to wordlist:
            [e] english
            [l] lorem
            Added #{red 'dolar'} to lorem wordlist
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT
        end
      end

      it 'can bail early when trying to replace with R' do
        run_exe 'spellr -i' do |stdout, stdin, pid|
          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.print 'R'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{aqua '>>'} #{red 'dolar'}
            #{aqua '=>'} dolar
          STDOUT

          stdin.puts "\u0003" # ctrl c

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{aqua '>>'} #{red 'dolar'}
            #{aqua '=>'} dolar
            ^C again to exit
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.puts "\u0003" # ctrl c

          expect(pid).to have_exitstatus(1)
        end
      end

      it 'returns the next unmatched term and a prompt after replacing with R' do
        run_exe 'spellr -i' do |stdout, stdin|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.print 'R'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{aqua '>>'} #{red 'dolar'}
            #{aqua '=>'} dolar
          STDOUT

          stdin.print "es\n"

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{aqua '>>'} #{red 'dolar'}
            #{aqua '=>'} dolares
            Replaced #{red('dolar')} with #{green('dolares')}
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolares'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          expect(check_file.read).to eq <<~FILE
            lorem ipsum dolares

              dolar amet
          FILE

          stdin.print 'a'

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{aqua '>>'} #{red 'dolar'}
            #{aqua '=>'} dolares
            Replaced #{red('dolar')} with #{green('dolares')}
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolares'}
            Add #{red 'dolares'} to wordlist:
            [e] english
          STDOUT

          stdin.print 'e'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{aqua '>>'} #{red 'dolar'}
            #{aqua '=>'} dolares
            Replaced #{red('dolar')} with #{green('dolares')}
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolares'}
            Add #{red 'dolares'} to wordlist:
            [e] english
            Added #{red('dolares')} to english wordlist
            Automatically replaced #{red('dolar')} with #{green('dolares')}
            #{aqua 'check.txt:3:10'} dolares #{red 'amet'}
            #{bold '[r,R,s,S,a,e,?]'}
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
            #{aqua '>>'} #{red 'dolar'}
            #{aqua '=>'} dolares
            Replaced #{red('dolar')} with #{green('dolares')}
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolares'}
            Add #{red 'dolares'} to wordlist:
            [e] english
            Added #{red('dolares')} to english wordlist
            Automatically replaced #{red('dolar')} with #{green('dolares')}
            #{aqua 'check.txt:3:10'} dolares #{red 'amet'}
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
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.print 'r'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{aqua '>>'} #{red 'dolar'}
            #{aqua '=>'} dolar
          STDOUT

          stdin.puts "\u0003" # ctrl c

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{aqua '>>'} #{red 'dolar'}
            #{aqua '=>'} dolar
            ^C again to exit
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.puts "\u0003" # ctrl c

          expect(pid).to have_exitstatus(1)
        end
      end

      it 'disallows replacing with nothing when replacing with r' do
        run_exe 'spellr -i' do |stdout, stdin|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.print 'r'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{aqua '>>'} #{red 'dolar'}
            #{aqua '=>'} dolar
          STDOUT

          stdin.puts "\b" * 17

          # just put the prompt again
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{aqua '>>'} #{red 'dolar'}
            #{aqua '=>'}
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT
        end
      end

      it 'returns the next unmatched term and a prompt after replacing with r' do
        run_exe 'spellr -i' do |stdout, stdin|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.print 'r'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{aqua '>>'} #{red 'dolar'}
            #{aqua '=>'} dolar
          STDOUT

          stdin.print "es\n"

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{aqua '>>'} #{red 'dolar'}
            #{aqua '=>'} dolares
            Replaced #{red('dolar')} with #{green('dolares')}
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolares'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          expect(check_file.read).to eq <<~FILE
            lorem ipsum dolares

              dolar amet
          FILE

          stdin.print 'a'

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{aqua '>>'} #{red 'dolar'}
            #{aqua '=>'} dolares
            Replaced #{red('dolar')} with #{green('dolares')}
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolares'}
            Add #{red 'dolares'} to wordlist:
            [e] english
          STDOUT

          stdin.print 'e'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{aqua '>>'} #{red 'dolar'}
            #{aqua '=>'} dolares
            Replaced #{red('dolar')} with #{green('dolares')}
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolares'}
            Add #{red 'dolares'} to wordlist:
            [e] english
            Added #{red 'dolares'} to english wordlist
            #{aqua 'check.txt:3:2'} #{red 'dolar'} amet
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          expect(english_wordlist.read).to eq <<~FILE
            dolares
            ipsum
            lorem
          FILE

          stdin.print 's'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{aqua '>>'} #{red 'dolar'}
            #{aqua '=>'} dolares
            Replaced #{red('dolar')} with #{green('dolares')}
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolares'}
            Add #{red 'dolares'} to wordlist:
            [e] english
            Added #{red 'dolares'} to english wordlist
            #{aqua 'check.txt:3:2'} #{red 'dolar'} amet
            Skipped #{red 'dolar'}
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.print 's'

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{aqua '>>'} #{red 'dolar'}
            #{aqua '=>'} dolares
            Replaced #{red('dolar')} with #{green('dolares')}
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolares'}
            Add #{red 'dolares'} to wordlist:
            [e] english
            Added #{red 'dolares'} to english wordlist
            #{aqua 'check.txt:3:2'} #{red 'dolar'} amet
            Skipped #{red 'dolar'}
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            Skipped #{red 'amet'}

            1 file checked
            4 errors found
            2 errors skipped
            1 error fixed
            1 word added
          STDOUT
        end
      end

      it 'returns the next unmatched term and a prompt after replacing with e' do
        run 'spellr -i' do |stdout, stdin|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.print 'e'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{aqua '>>'} lorem ipsum #{red 'dolar'}
            #{aqua '=>'} lorem ipsum dolar
          STDOUT
          stdin.print "\b" * 17
          stdin.print "lorem lorem lorem\n"

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{aqua '>>'} lorem ipsum #{red 'dolar'}
            #{aqua '=>'} lorem lorem lorem
            Replaced #{red 'lorem ipsum dolar'} with #{green('lorem lorem lorem')}
            #{aqua 'check.txt:3:2'} #{red 'dolar'} amet
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          expect(check_file.read).to eq <<~FILE
            lorem lorem lorem

              dolar amet
          FILE

          stdin.print 's'

          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{aqua '>>'} lorem ipsum #{red 'dolar'}
            #{aqua '=>'} lorem lorem lorem
            Replaced #{red 'lorem ipsum dolar'} with #{green('lorem lorem lorem')}
            #{aqua 'check.txt:3:2'} #{red 'dolar'} amet
            Skipped #{red 'dolar'}
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.print 's'

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{aqua '>>'} lorem ipsum #{red 'dolar'}
            #{aqua '=>'} lorem lorem lorem
            Replaced #{red 'lorem ipsum dolar'} with #{green('lorem lorem lorem')}
            #{aqua 'check.txt:3:2'} #{red 'dolar'} amet
            Skipped #{red 'dolar'}
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            Skipped #{red 'amet'}

            1 file checked
            3 errors found
            2 errors skipped
            1 error fixed
          STDOUT
        end
      end
    end
  end
end

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
      expect(stdout.split("\n")).to contain_exactly(
        'lib/bar.rb',
        'foo.md'
      )
    end

    it 'returns the list of files when given an extensions to subset' do
      run('spellr --dry-run \*.rb')

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout).to eq 'lib/bar.rb'
    end

    it 'returns the list of files when given a dir to subset' do
      run('spellr --dry-run lib/')

      expect(stderr).to be_empty
      expect(exitstatus).to eq 0
      expect(stdout).to eq 'lib/bar.rb'
    end
  end

  context 'with files with errors' do
    around do |example|
      with_temp_dir { example.run }
    end

    before do
      stub_fs_file '.spellr_wordlists/english.txt', <<~FILE
        ipsum
        lorem
      FILE

      stub_fs_file 'check.txt', <<~FILE
        lorem ipsum dolar

          dolar amet
      FILE
    end

    describe '--wordlist' do
      it 'returns the list of unmatched words' do # rubocop:disable RSpec/ExampleLength
        run 'spellr --wordlist'

        expect(stderr).to be_empty
        expect(exitstatus).to eq 1
        expect(stdout).to eq <<~WORDS.chomp
          amet
          dolar
        WORDS
      end
    end

    describe 'spellr' do
      it 'returns the list of unmatched words and their locations' do # rubocop:disable RSpec/ExampleLength
        run 'spellr'

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
        run 'spellr -i' do |stdout, _|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT
        end
      end

      it 'returns the interactive command help' do # rubocop:disable RSpec/ExampleLength
        run 'spellr -i' do |stdout, stdin|
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

      it 'exits when ctrl C' do # rubocop:disable RSpec/ExampleLength
        run 'spellr -i' do |stdout, stdin, pid|
          expect(stdout).to print <<~STDOUT.chomp
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            #{bold '[r,R,s,S,a,e,?]'}
          STDOUT

          stdin.puts "\u0003" # ctrl c

          expect(pid).to have_exitstatus(1)
        end
      end

      it 'returns the next unmatched term and a prompt after skipping' do # rubocop:disable RSpec/ExampleLength
        run 'spellr -i' do |stdout, stdin|
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

      it 'returns the next unmatched term and a prompt after skipping with S' do # rubocop:disable RSpec/ExampleLength
        run 'spellr -i' do |stdout, stdin|
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

      it 'returns the next unmatched term and a prompt after adding with a' do # rubocop:disable RSpec/ExampleLength
        run 'spellr -i' do |stdout, stdin|
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

          stdin.print 's'

          expect(stdout).to print <<~STDOUT
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolar'}
            Add #{red 'dolar'} to wordlist:
            [e] english
            Added #{red 'dolar'} to english wordlist
            #{aqua 'check.txt:3:8'} dolar #{red 'amet'}
            Skipped #{red 'amet'}

            1 file checked
            2 errors found
            1 error skipped
            1 word added
          STDOUT
        end
      end

      it 'returns the next unmatched term and a prompt after replacing with R' do # rubocop:disable RSpec/ExampleLength
        run 'spellr -i' do |stdout, stdin|
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

      it 'returns the next unmatched term and a prompt after replacing with r' do # rubocop:disable RSpec/ExampleLength
        run 'spellr -i' do |stdout, stdin| # rubocop:disable Metrics/BlockLength
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

      it 'returns the next unmatched term and a prompt after replacing with e' do # rubocop:disable RSpec/ExampleLength
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

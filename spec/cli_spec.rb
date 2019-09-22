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

          dolor amet
      FILE

      stub_fs_file '.spellr.yml', <<~FILE
        color: true
        ignore:
          - .spellr.yml
      FILE
    end

    describe '--wordlist' do
      it 'returns the list of unmatched words' do # rubocop:disable RSpec/ExampleLength
        run 'spellr --wordlist'

        expect(stderr).to be_empty
        expect(exitstatus).to eq 1
        expect(stdout).to eq <<~WORDS.chomp
          amet
          dolor
        WORDS
      end
    end

    describe 'spellr' do
      it 'returns the list of unmatched words and their locations' do # rubocop:disable RSpec/ExampleLength
        run 'spellr'

        expect(stderr).to be_empty
        expect(exitstatus).to eq 1
        expect(stdout).to eq <<~WORDS.chomp
          #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
          #{aqua 'check.txt:3:2'} #{red 'dolor'} amet
          #{aqua 'check.txt:3:8'} dolor #{red 'amet'}

          1 file checked
          3 errors found
        WORDS
      end
    end

    describe '--interactive' do
      it 'returns the first unmatched term and a prompt' do
        run 'spellr -i' do |stdout, _stdin|
          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{bold '[a,s,S,r,R,e,?]'}
          STDOUT
        end
      end

      it 'returns the interactive command help' do # rubocop:disable RSpec/ExampleLength
        run 'spellr -i' do |stdout, stdin|
          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{bold '[a,s,S,r,R,e,?]'}
          STDOUT

          stdin.print '?'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{bold '[r]'} Replace #{red 'dolor'}
            #{bold '[R]'} Replace all future instances of #{red 'dolor'}
            #{bold '[s]'} Skip #{red 'dolor'}
            #{bold '[S]'} Skip all future instances of #{red 'dolor'}
            #{bold '[a]'} Add #{red 'dolor'} to a word list
            #{bold '[e]'} Edit the whole line
            #{bold '[?]'} Show this help
          STDOUT
        end
      end

      it 'exits when ctrl C' do # rubocop:disable RSpec/ExampleLength
        run 'spellr -i' do |stdout, stdin, pid|
          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{bold '[a,s,S,r,R,e,?]'}
          STDOUT

          stdin.puts "\u0003" # ctrl c

          expect { PTY.check(pid)&.exitstatus }.to eventually(eq 1)
        end
      end

      it 'returns the next unmatched term and a prompt after skipping' do # rubocop:disable RSpec/ExampleLength
        run 'spellr -i' do |stdout, stdin|
          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{bold '[a,s,S,r,R,e,?]'}
          STDOUT

          stdin.print 's'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{aqua 'check.txt:3:2'} #{red 'dolor'} amet
            #{bold '[a,s,S,r,R,e,?]'}
          STDOUT

          stdin.print 's'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{aqua 'check.txt:3:2'} #{red 'dolor'} amet
            #{aqua 'check.txt:3:8'} dolor #{red 'amet'}
            #{bold '[a,s,S,r,R,e,?]'}
          STDOUT

          stdin.print 's'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{aqua 'check.txt:3:2'} #{red 'dolor'} amet
            #{aqua 'check.txt:3:8'} dolor #{red 'amet'}

            1 file checked
            3 errors found
            3 errors skipped

          STDOUT
        end
      end

      it 'returns the next unmatched term and a prompt after skipping with S' do # rubocop:disable RSpec/ExampleLength
        run 'spellr -i' do |stdout, stdin|
          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{bold '[a,s,S,r,R,e,?]'}
          STDOUT

          stdin.print 'S'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{aqua 'check.txt:3:8'} dolor #{red 'amet'}
            #{bold '[a,s,S,r,R,e,?]'}
          STDOUT

          stdin.print 'S'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{aqua 'check.txt:3:8'} dolor #{red 'amet'}

            1 file checked
            3 errors found
            3 errors skipped

          STDOUT
        end
      end

      it 'returns the next unmatched term and a prompt after adding with a' do # rubocop:disable RSpec/ExampleLength
        run 'spellr -i' do |stdout, stdin|
          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{bold '[a,s,S,r,R,e,?]'}
          STDOUT

          stdin.print 'a'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            Add #{red 'dolor'} to wordlist:
            [0] english
          STDOUT

          stdin.print '0'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            Add #{red 'dolor'} to wordlist:
            [0] english
            #{aqua 'check.txt:3:8'} dolor #{red 'amet'}
            #{bold '[a,s,S,r,R,e,?]'}
          STDOUT

          stdin.print 's'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            Add #{red 'dolor'} to wordlist:
            [0] english
            #{aqua 'check.txt:3:8'} dolor #{red 'amet'}

            1 file checked
            2 errors found
            1 error skipped
            1 word added
          STDOUT
        end
      end

      it 'returns the next unmatched term and a prompt after replacing with R' do # rubocop:disable RSpec/ExampleLength
        run 'spellr -i' do |stdout, stdin|
          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{bold '[a,s,S,r,R,e,?]'}
          STDOUT

          stdin.print 'R'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '=>'} dolor
          STDOUT

          stdin.print "es\n"

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '=>'} dolores
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolores'}
            #{bold '[a,s,S,r,R,e,?]'}
          STDOUT

          stdin.print 'a'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '=>'} dolores
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolores'}
            Add #{red 'dolores'} to wordlist:
            [0] english
          STDOUT

          stdin.print '0'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '=>'} dolores
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolores'}
            Add #{red 'dolores'} to wordlist:
            [0] english
            #{aqua 'check.txt:3:10'} dolores #{red 'amet'}
            #{bold '[a,s,S,r,R,e,?]'}
          STDOUT

          stdin.print 's'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '=>'} dolores
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolores'}
            Add #{red 'dolores'} to wordlist:
            [0] english
            #{aqua 'check.txt:3:10'} dolores #{red 'amet'}

            1 file checked
            4 errors found
            1 error skipped
            2 errors fixed
            1 word added
          STDOUT
        end
      end

      it 'returns the next unmatched term and a prompt after replacing with r' do # rubocop:disable RSpec/ExampleLength
        run 'spellr -i' do |stdout, stdin|
          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{bold '[a,s,S,r,R,e,?]'}
          STDOUT

          stdin.print 'r'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '=>'} dolor
          STDOUT

          stdin.print "es\n"

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '=>'} dolores
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolores'}
            #{bold '[a,s,S,r,R,e,?]'}
          STDOUT

          stdin.print 'a'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '=>'} dolores
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolores'}
            Add #{red 'dolores'} to wordlist:
            [0] english
          STDOUT

          stdin.print '0'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '=>'} dolores
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolores'}
            Add #{red 'dolores'} to wordlist:
            [0] english
            #{aqua 'check.txt:3:2'} #{red 'dolor'} amet
            #{bold '[a,s,S,r,R,e,?]'}
          STDOUT

          stdin.print 's'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '=>'} dolores
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolores'}
            Add #{red 'dolores'} to wordlist:
            [0] english
            #{aqua 'check.txt:3:2'} #{red 'dolor'} amet
            #{aqua 'check.txt:3:8'} dolor #{red 'amet'}
            #{bold '[a,s,S,r,R,e,?]'}
          STDOUT

          stdin.print 's'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '>>'} #{red 'dolor'}
            #{aqua '=>'} dolores
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolores'}
            Add #{red 'dolores'} to wordlist:
            [0] english
            #{aqua 'check.txt:3:2'} #{red 'dolor'} amet
            #{aqua 'check.txt:3:8'} dolor #{red 'amet'}

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
          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{bold '[a,s,S,r,R,e,?]'}
          STDOUT

          stdin.print 'e'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{aqua '>>'} lorem ipsum #{red 'dolor'}
            #{aqua '>>'} lorem ipsum #{red 'dolor'}
            #{aqua '=>'} lorem ipsum dolor
          STDOUT
          stdin.print "\b" * 17
          stdin.print "lorem lorem lorem\n"

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{aqua '>>'} lorem ipsum #{red 'dolor'}
            #{aqua '>>'} lorem ipsum #{red 'dolor'}
            #{aqua '=>'} lorem lorem lorem
            #{aqua 'check.txt:3:2'} #{red 'dolor'} amet
            #{bold '[a,s,S,r,R,e,?]'}
          STDOUT

          stdin.print 's'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT.chomp)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{aqua '>>'} lorem ipsum #{red 'dolor'}
            #{aqua '>>'} lorem ipsum #{red 'dolor'}
            #{aqua '=>'} lorem lorem lorem
            #{aqua 'check.txt:3:2'} #{red 'dolor'} amet
            #{aqua 'check.txt:3:8'} dolor #{red 'amet'}
            #{bold '[a,s,S,r,R,e,?]'}
          STDOUT

          stdin.print 's'

          expect { accumulate_io(stdout) }.to eventually(eq <<~STDOUT)
            #{aqua 'check.txt:1:12'} lorem ipsum #{red 'dolor'}
            #{aqua '>>'} lorem ipsum #{red 'dolor'}
            #{aqua '=>'} lorem lorem lorem
            #{aqua 'check.txt:3:2'} #{red 'dolor'} amet
            #{aqua 'check.txt:3:8'} dolor #{red 'amet'}

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

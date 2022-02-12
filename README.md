# Spellr

[![Build Status](https://travis-ci.com/robotdana/spellr.svg?branch=main)](https://travis-ci.com/robotdana/spellr)
[![Gem Version](https://badge.fury.io/rb/spellr.svg)](https://rubygems.org/gems/spellr)

Spell check your source code for fun and occasionally finding bugs

This is inspired by https://github.com/myint/scspell, and uses wordlists from [SCOWL](http://wordlist.aspell.net) and [MDN](http://wiki.developer.mozilla.org/).

## What makes a spell checker a source code spell checker?

1. It tokenizes CamelCase and snake_case and kebab-case and checks these as independent words including CAMELCase with acronyms.
2. It skips urls
3. It skips things that heuristically look like base64 or hex strings rather than words. This uses a bayesian classifier and is not magic. Find the balance of false-positive to false-negative that works for you with the `key_heuristic_weight` [configuration](#configuration) option.
4. It comes with some wordlists for built in commands in some common programming languages, and recognizes hashbangs.
5. Configure whether you want US, AU, CA, or GB english (or all of them).
6. It checks directories recursively, obeying .gitignore
7. It's easy to add terms to wordlists
8. It's easy to integrate with CI pipelines
7. It's very configurable

## A brief aside on "correct" spelling.

There's no correct way to spell anything. You can't trust dictionaries, they only react to the way everyone else uses words. Any agreement about certain spellings is a collective hallucination, and is a terrible proxy for attention or intelligence or education or value. Those who get to declare what "correct" spelling is, or even what counts as a real word, tend to be those groups that have more social power and it's (sometimes unconsciously) used as a way to maintain that power.

However, in a programming context spelling things _consistently_ is useful, where method definitions must match method calls, and comments about these are clearer when also matching. It also makes grepping easier, not that you'd find the word 'grepping' in most dictionaries.

## Installation

This is tested against ruby 2.5-3.0.

### With Bundler

Add this line to your application's `Gemfile`:

```ruby
gem 'spellr', require: false
```

Then execute:

```bash
$ bundle install
```

### With Rubygems

```bash
$ gem install spellr
```

### With Docker

execute this command instead of `spellr`. This is otherwise identical to using the gem version

```bash
$ docker run -it -v $PWD:/app robotdana/spellr
```

## Usage

The main way to interact with `spellr` is through the executable.

```bash
$ spellr # will run the spell checker
$ spellr --interactive # will run the spell checker, interactively
$ spellr --wordlist # will output all words that fail the spell checker in spellr wordlist format
$ spellr --quiet # will suppress all output
$ spellr --autocorrect # for if you're feeling lucky
```

To check a single file or subset of files, just add paths or globs:
```bash
$ spellr --interactive path/to/my/file.txt and/another/file.sh
$ spellr --wordlist '*.rb' '*_test.js'
```

There are some support commands available:

```bash
$ spellr --dry-run # list files that will be checked
$ spellr --version # for the current version
$ spellr --help # for the list of flags available
```

### First run

Feel free to just `spellr --interactive` and go, but I prefer this process when first adding spellr to a large project.

```bash
$ spellr --dry-run
```

Look at the list of files, are there some that shouldn't be checked (generated files etc)? .gitignored files and some binary file extensions are already skipped by default.

Add any additional files to ignore to a `.spellr.yml` file in your project root directory.
```yml
excludes:
  - ignore
  - /generated
  - "!files"
  - in/*
  - .gitignore
  - "*.format"
```

Then output the existing words that fail the default dictionaries.
```bash
$ spellr --wordlist > .spellr-wordlists/english.txt
```

Open `.spellr-wordlists/english.txt` and remove those lines that look like typos or mistakes, leaving the file in ascii order.

Now it's time to run the interactive spell checker

```bash
$ spellr --interactive
```

### Interactive spell checking

To start an interactive spell checking session:
```bash
$ spellr --interactive
```

You'll be shown each word that's not found in a dictionary, it's location (path:line:column), along with suggestions, and a prompt.
```
file.rb:1:0 notaword
Did you mean: [1] notwork, [2] nonword
[a]dd, [r]eplace, [s]kip, [h]elp, [^C] to exit: [ ]
```

Type `h` for this list of what each letter command does
```
[1]...[2] Replace notaword with the numbered suggestion
[a] Add notaword to a word list
[r] Replace notaword
[R] Replace this and all future instances of notaword
[s] Skip notaword
[S] Skip this and all future instances of notaword
[h] Show this help
[ctrl] + [C] Exit spellr

What do you want to do? [ ]
```

---

If you type a numeral the word will be replaced with that numbered suggestion
```
file.txt:1:0 notaword
Did you mean: [1] notwork, [2] nonword
[a]dd, [r]eplace, [s]kip, [h]elp, [^C] to exit: [2]
Replaced notaword with nonword
```

---

If you type `r` or `R` you'll be shown a prompt with the original word and it prefilled ready for correcting:
```
file.txt:1:0 notaword
Did you mean: [1] notwork, [2] nonword
[a]dd, [r]eplace, [s]kip, [h]elp, [^C] to exit: [r]

  [^C] to go back
  Replace notaword with: notaword
```
To submit your choice and continue with the spell checking click enter. Your replacement word will be immediately spellchecked. To instead go back press Ctrl-C once (pressing it twice will exit the spell checking).

Lowercase `r` will correct this particular use of the word, uppercase `R` will also all the future times that word is used.

---

If you instead type `s` or `S` it will skip this word and continue with the spell checking.

Lowercase `s` will skip this particular use of the word, uppercase `S` will also skip future uses of the word.

---

If you instead type `a` you'll be shown a list of possible wordlists to add to. This list is based on the file path, and is configurable in `.spellr.yml`.
```
file.txt:1:0 notaword
Did you mean: [1] notwork, [2] nonword
[a]dd, [r]eplace, [s]kip, [h]elp, [^C] to exit: [a]

  [e] english
  [^C] to go back
  Add notaword to which wordlist? [ ]
```
Type `e` to add this word to the english wordlist and continue on through the spell checking. To instead go back to the prompt press Ctrl-C once (pressing it twice will exit the spell checking).

### Disabling the tokenizer

If the tokenizer finds a word you don't want to add to the wordlist (perhaps it's an intentional example of a typo, or a non-word string not excluded by the heuristic) then add any kind of comment containing `spellr:disable-line` to the line.
```ruby
open('mispeled_filename.txt') # spellr:disable-line
```

You can also disable multiple lines, by surrounding the offending code with `spellr:disable` and `spellr:enable`
```ruby
# spellr:disable
it "Test typo of the: teh" do
  fill_in(field, with: "teh")
end
# spellr:enable
```

If your language supports inline comments you can also surround with `spellr:disable` and `spellr:enable` in the same line:
```html
<span><!-- spellr:disable -->nonsenseword<!-- spellr:enable --></span>
```
## Configuration

Spellr's configuration is a `.spellr.yml` file in your project root. This is combined with the gem defaults defined [here](https://github.com/robotdana/spellr/blob/main/lib/.spellr.yml).
There are top-level keys and per-language keys.
```yml
word_minimum_length: 3 # any words shorter than this will be ignored
key_minimum_length: 6 # any strings shorter than this won't be considered non-word strings
key_heuristic_weight: 5 # higher values mean strings are more likely to be considered words or non-words by the classifier.
excludes:
  - ignore
  - "!files"
  - in/*
  - .gitignore
  - "*.format"
includes:
  - limit to
  - "files*"
  - in/*
  - .gitignore-esque
  - "*.format"
```
The includes format is documented [here](https://github.com/robotdana/fast_ignore#using-an-includes-list).

Also within this file are language definitions:
```yml
languages:
  english: # this must match exactly the name of the file in .spellr-wordlists/
    locale: # US, AU, CA, or GB
      - US
      - AU
  ruby:
    includes:
      - patterns*
      - "*_here.rb"
      - limit-which-files
      - the/wordlist/**/*
      - /applies_to/
    key: r # this is the letter used to choose this wordlist when using `spellr --interactive`.
    hashbangs:
      - ruby # if the file has no extension and the hashbang/shebang contains ruby
             # this file will match even if it doesn't otherwise match the includes pattern.
```

If you want a file to have a file-specific wordlist:
e.g. for terms specific to logstash:
```yml
languages:
  logstash: # this can be anything
    includes:
      - path/to/logstash/file
```

## Rake

Create or open a file in the root of your project named `Rakefile`.
adding the following lines
```ruby
# Rakefile
require 'spellr/rake_task'
Spellr::RakeTask.generate_task
```

This will add the `rake spellr` task. To provide arguments like the cli, use square brackets. (ensure you escape the `[]` if you're using zsh)
`rake 'spellr[--interactive]'`

To provide default cli arguments, the first argument is the name, and subsequent arguments are the cli arguments.
```ruby
# Rakefile
require 'spellr/rake_task'
Spellr::RakeTask.generate_task(:spellr_quiet, '--quiet')

task default: :spellr_quiet
```
or `rake spellr` will be in interactive mode unless the CI env variable is set.
```ruby
# Rakefile
require 'spellr/rake_task'
spellr_arguments = ENV['CI'] ? [] : ['--interactive']
Spellr::RakeTask.generate_task(:spellr, **spellr_arguments)

task default: :spellr
```

## Travis

To have this automatically run on travis, add `:spellr` to the default rake task.
```ruby
# Rakefile
require 'spellr/rake_task'
Spellr::RakeTask.generate_task

task default: :spellr
```
or if you already have :default task, add :spellr to the array.
```ruby
require 'spellr/rake_task'
Spellr::RakeTask.generate_task

task default: [:spec, :spellr]
```
or etc.

Also follow the travis documentation to have travis run rake:
```yml
# .travis.yml
sudo: false
language: ruby
cache: bundler
rvm:
  - 3.0
before_install: gem install bundler
```

## Ignoring the configured patterns

Sometimes you'll want to spell check something that would usually be ignored,
e.g. `.git/COMMIT_EDITMSG` even though `spellr` ignores the `.git` directory.

For this you can use the `--suppress-file-rules` command line argument.
```bash
$ spellr --suppress-file-rules .git/COMMIT_EDITMSG
```

**Note: This still ignores files outside of the current directory**

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/robotdana/spellr.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
Wordlists packaged with this gem have their own licenses, see them in https://github.com/robotdana/spellr/tree/main/wordlists

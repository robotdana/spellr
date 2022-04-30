# v0.10.1
- Resolve fast_ignore follow_symlinks deprecation

# v0.10.0
- Drop ruby 2.4 support, to allow for...
- Spelling suggestions while using `spellr --interactive`
- And a new, probably frequently wrong, `spellr --autocorrect`

# v0.9.1
- Assume all files are utf8, more comprehensively. (Sets ::Encoding.default_external and default_internal while running)

# v0.9.0
- Recognize url with _ in query string and zero length path
- Assume all files are utf8

# v0.8.8
- output a suggested `spellr --interactive` command with filenames, when running this without --interactive

# v0.8.7
- Recognize URL with tilde in path

# v0.8.6
- `--suppress--file-rules` so you can check files that would usually be ignored

# v0.8.5
- Single line disable! use `spellr:disable-line` #25

# v0.8.4
- Update fast_ignore dependency, it's faster now (about 0.5s faster on rails codebase)

# v0.8.3
- Update fast_ignore dependency fixing symlinks to directories handling.

# v0.8.2
- Massive test refactor
  - Spellr now only pays attention to Spellr.pwd. Dir.pwd can be whatever
  - All output goes through Spellr.config.output. Now we can override it.
  - tests are twice as fast. Fewer warnings
- upgrade fast_ignore dependency

# v0.8.1
- use refinements for backports so that RakeTask doesn't conflict with Rubocop::RakeTask

# v0.8.0
- add the ability to use spellr as a rake task

# v0.7.1
- relax fast_ignore requirement

# v0.7.0
- dry_run checks config validity
- require fast_ignore 0.6.0
- new interactive UI
- misc performance improvements

# v0.6.0
- add CSS wordlist from MDN
- improve html wordlist comprehensiveness from MDN and W3C
- add ruby 2.7 words

# v0.5.3
- update fast_ignore requirement. it's slightly faster.
- misc other performance improvements

# v0.5.2
- require Parallel dependency in gemspec (oops)

# v0.5.1
- Check files in parallel
- Lots of pure refactoring
- Capfile is now considered a ruby file by default

# v0.5.0
- Removed the fetch command it was just unnecessarily slow and awkward. instead use `locale: [US,AU]`
- Added usage documentation
- Fixed an issue where file-specific wordlists couldn't be added to

# v0.4.1
- fix the private method 'touch' issue when generating wordlists
- fix the js/javascript defaults being named differently (now consistently is named javascript)
- add .jsx.snap and .tsx.snap as extensions using the javascript wordlists

# v0.4.0
- LOTS of performance improvements. it's about 4 times faster
- significantly better key heuristic matching, with configurable weight (`key_heuristic_weight`).
- Update FastIgnore dependency.
- Change the yml format slightly. `ignore` is now `excludes`. `only` is now `includes`
  I feel like this makes more sense for the way the config is merged. and the right time to do it is when you'll probably have to tweak it anyway because:
- the `only`/`includes` items are now parsed using FastIgnore's gitignore inspired allow list format
  (see https://github.com/robotdana/fast_ignore#using-an-includes-list)
  Mostly it's the same just more flexible, though there may need to be some small adjustments.
- the cli arguments are now also managed using FastIgnore's rules, fixing issues with absolute paths and paths beginning with `./` also it's a LOT faster when just checking a single file, basically instant. so that's nice.

# v0.3.2
- add automatic rubygems and dockerhub deploy

# v0.3.1
- remove unnecessary files

# v0.3.0
- interactive add to wordlist uses consistent letters rather than random numbers as keys
- additional wordlists per language can no longer be defined

# v0.2.0
- Supports ruby 2.3 - 2.6

# v0.1.0
- Initial Release

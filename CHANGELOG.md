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

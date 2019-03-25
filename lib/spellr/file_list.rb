require 'pathname'

module Spellr
  class FileList
    attr_accessor :globs
    include Enumerable

    def self.glob(*globs, &block)
      return [] if globs.empty?
      globs = globs.map { |g| g.to_s.start_with?('*') ? "**/#{g}" : g }
      glob = globs.length == 1 ? globs.first : "{#{globs.join(",")}}"
      Pathname.pwd.glob(glob, ::File::FNM_DOTMATCH | ::File::FNM_EXTGLOB, &block)
    end

    def initialize(*globs)
      @globs = globs
    end

    def globs
      return ['*'] if @globs.empty?
      @globs
    end

    def globs=(values)
      @files = nil
      @globs = values
    end

    def join(*_)
      to_a.join(*_)
    end

    def excluded?(file)
      @exclusions ||= Spellr::FileList.glob(*Spellr.config.exclusions).sort

      @exclusions.bsearch { |value| file <=> value }
    end

    def dictionary?(file)
      @dictionaries ||= Spellr.config.dictionaries.map { |k,v| v.file }.sort

      @dictionaries.bsearch { |value| file <=> value }
    end

    # TODO: replace with a reasonably fast ruby version
    def gitignored?(file)
      @gitignore_allowed ||= begin
        pwd = Dir.pwd
        `git ls-files`.split("\n").map { |path| "#{pwd}/#{path}" }
      end

      return if @gitignore_allowed.empty?

      !@gitignore_allowed.bsearch { |value| file.to_s <=> value }
    end

    def each(&block)
      self.class.glob(*globs).lazy.each do |file|
        next unless file.file?
        next if dictionary?(file)
        next if gitignored?(file)
        next if excluded?(file)
        file = Spellr::File.new(file)
        block.call(file)
      end
    end

    def to_a
      enum_for(:each).to_a
    end
  end
end

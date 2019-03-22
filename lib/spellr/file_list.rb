require 'pathname'

module Spellr
  class FileList
    attr_accessor :globs
    include Enumerable

    def initialize(globs: [])
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

    def each(&block)
      files.each(&block)
    end

    def join(*_)
      to_a.join(*_)
    end

    def files
      @files ||= globs.flat_map do |glob|
        glob = "**/#{glob}" if glob.include?('*')
        Dir.glob(glob, ::File::FNM_DOTMATCH | ::File::FNM_EXTGLOB)
      end.map do |file|
        file = Spellr::File.new(file)
        next unless file.checkable?
        file
      end.compact
    end
  end
end

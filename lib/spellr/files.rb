require 'pathname'

module Spellr
  class Files
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

    def files
      @files ||= globs.flat_map do |glob|
        glob = "**/#{glob}" if glob.include?('*')
        Pathname.glob(glob)
      end.select(&:file?)
    end
  end
end

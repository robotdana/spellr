require 'pathname'

module Spellr
  class Dictionary
    DIR = Pathname.new(__FILE__).join('..', '..', '..', 'dictionaries')

    include Enumerable

    def self.[](name)
      @registry ||= {}
      @registry[name] ||= new(name)
    end

    def initialize(name)
      @name = name
    end

    def file
      DIR.join("#{name}.txt")
    end

    def license_file
      DIR.join("#{name}.LICENSE.txt")
    end

    def each(&block)
      enumerator.rewind
      enumerator.each(&block)
    end

    private

    attr_reader :name

    def enumerator
      @enumerator ||= file.each_line.lazy
    end
  end
end

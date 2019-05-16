# frozen_string_literal: true

require 'pathname'
require_relative '../spellr'

module Spellr
  class Wordlist
    class NotFound < Spellr::Error; end

    include Enumerable

    attr_reader :path

    def initialize(file)
      path = @file = file
      path = path.sub('$GEM', ::File.join(__dir__, '..', '..', 'wordlists'))
      path = path.sub('$PROJECT', Dir.pwd)
      @path = Pathname.new(path).expand_path
    end

    def each(&block)
      raise_unless_exists?

      @path.each_line(&block)
    end

    def inspect
      "#<#{self.class.name}:#{@path}>"
    end

    # significantly faster than default Enumerable#include?
    def include?(term)
      term = term.downcase + "\n"
      @include ||= {}
      @include[term] ||= to_a.bsearch { |value| term <=> value }
    end

    def to_a
      @to_a ||= super
    end

    def clean(words = read)
      require_relative 'tokenizer'
      tokens = Spellr::Tokenizer.new(words).tokenize.map(&:downcase).uniq.sort

      write(tokens.join("\n") + "\n")
    end

    def write(content)
      @path.write(content)

      clear_cache
    end

    def read
      raise_unless_exists?

      @path.read
    end

    def clear_cache
      @to_a = nil
      @include = nil
    end

    private

    def raise_unless_exists?
      return if @path.exist?

      raise Spellr::Wordlist::NotFound, "Wordlist file #{@file} doesn't exist at #{@path}"
    end
  end
end

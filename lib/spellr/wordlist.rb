# frozen_string_literal: true

require 'pathname'
require_relative '../spellr'

module Spellr
  class Wordlist
    class NotFound < Spellr::Error; end

    include Enumerable

    attr_reader :path, :name

    def initialize(file, name: file)
      path = @file = file
      @path = Pathname.pwd.join('.spellr_wordlists').join(path).expand_path
      @name = name
    end

    def each(&block)
      raise_unless_exists?

      @path.each_line(&block)
    end

    def inspect
      "#<#{self.class.name}:#{@path}>"
    end

    # significantly faster than default Enumerable#include?
    # requires terms to be sorted
    def include?(term)
      term = term.downcase + "\n"
      @include ||= {}
      @include.fetch(term, to_a.bsearch { |value| term <=> value })
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

    def exist?
      @path.exist?
    end

    def add(term)
      term = term.downcase + "\n"
      @include ||= {}
      @include[term] = true
      @to_a ||= []
      to_a << term
      write(to_a.sort.join(''))
    end

    private

    def raise_unless_exists?
      return if exist?

      raise Spellr::Wordlist::NotFound, "Wordlist file #{@file} doesn't exist at #{@path}"
    end
  end
end

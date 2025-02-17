# frozen_string_literal: true

require 'pathname'
require_relative '../spellr'
require_relative 'token' # for spellr_normalize

module Spellr
  class Wordlist
    include Enumerable

    attr_reader :path, :name

    def initialize(file, name: file)
      path = @file = file
      @path = Spellr.pwd.join('.spellr_wordlists').join(path).expand_path
      @name = name
      @include = {}
    end

    def each(&block)
      words.each(&block)
    end

    # :nocov:
    def inspect
      "#<#{self.class.name}:#{@path}>"
    end
    # :nocov:

    # significantly faster than default Enumerable#include?
    # requires terms to have been sorted
    def include?(term)
      term = term.spellr_normalize
      @include.fetch(term) do
        @include[term] = words.bsearch { |value| term <=> value }
      end
    end

    def <<(term)
      term = term.spellr_normalize
      touch
      @include[term] = true
      insert_sorted(term)
      write(words, clear_cache: false)
    end

    def words
      @words ||= if exist?
        @path.readlines(chomp: true)
      else
        []
      end
    end
    alias_method :to_a, :words

    def clean(file = @path)
      require_relative 'tokenizer'
      write(Spellr::Tokenizer.new(file, skip_key: false).normalized_terms)
    end

    def write(words, clear_cache: true)
      content = words.join("\n")
      content << "\n" unless words.empty?
      @path.write(content)

      self.clear_cache if clear_cache
    end

    def exist?
      return @exist if defined?(@exist)

      @exist = @path.exist?
    end

    def touch
      return if exist?

      @path.dirname.mkpath
      write([])
    end

    def length
      to_a.length
    end

    def insert_sorted(term)
      insert_at = words.bsearch_index { |value| value >= term }
      insert_at ? words.insert(insert_at, term) : words.push(term)
    end

    def clear_cache
      @words = nil
      @include = {}
      remove_instance_variable(:@exist) if defined?(@exist)
    end
  end
end

# frozen_string_literal: true

require 'pathname'
require_relative '../spellr'
require_relative 'token'

module Spellr
  class Wordlist
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
    # requires terms to have been sorted
    def include?(term)
      include_cache[term.spellr_normalize]
    end

    def <<(term)
      term = term.spellr_normalize
      touch
      include_cache[term] = true
      insert_sorted(term)
      @path.write(to_a.join) # we don't need to clear the cache
    end

    def to_a
      @to_a ||= super
    end

    def clean(file = @path)
      require_relative 'tokenizer'
      write(Spellr::Tokenizer.new(file, skip_key: false).normalized_terms.join)
    end

    def write(content)
      @path.write(content)

      clear_cache
    end

    def read
      raise_unless_exists?

      @path.read
    end

    def exist?
      return @exist if defined?(@exist)

      @exist = @path.exist?
    end

    def touch
      return if exist?

      @path.dirname.mkpath
      @path.write('')
      clear_cache
    end

    private

    def insert_sorted(term)
      insert_at = to_a.bsearch_index { |value| value >= term }
      insert_at ? to_a.insert(insert_at, term) : to_a.push(term)
    end

    def include_cache
      @include_cache ||= Hash.new do |cache, term|
        cache[term] = to_a.bsearch do |value|
          term <=> value
        end
      end
    end

    def clear_cache
      @to_a = nil
      @include = nil
      remove_instance_variable(:@exist) if defined?(@exist)
    end

    def raise_unless_exists?
      return if exist?

      raise Spellr::Wordlist::NotFound, "Wordlist file #{@file} doesn't exist at #{@path}"
    end
  end
end

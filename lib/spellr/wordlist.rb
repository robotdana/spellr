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
      include_cache[term]
    end

    def include_cache
      @include_cache ||= Hash.new do |cache, term|
        term = Spellr::Token.normalize(term)
        cache[term] = to_a.bsearch do |value|
          term <=> value
        end
      end
    end

    def to_a
      @to_a ||= super
    end

    def clean(words = read) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      require_relative 'tokenizer'
      require_relative 'token'
      puts "tokenizing #{name} wordlist"

      # tokenizer is way to slow with large files currently
      # tokens = Spellr::Tokenizer.new(words).words

      puts "stripping trailing bits from #{name} wordlist"
      tokens = words.each_line.map { |x| x.strip.gsub("'s", '') }
      puts "normalizing #{name} wordlist"
      tokens = tokens.map { |t| Spellr::Token.normalize(t) }
      puts "Removing short words from #{name} wordlist"
      tokens = tokens.reject { |x| x.length < Spellr.config.word_minimum_length + 1 } # the plus 1 is the newline

      puts "sorting #{name} wordlist"
      tokens = tokens.uniq.sort
      puts "writing #{name} wordlist"
      write(tokens.join(''))
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
      touch
      term = Spellr::Token.normalize(term)
      include_cache[term] = true
      to_a << term
      to_a.sort!
      write(@to_a.join)
      Spellr.config.clear_cache if to_a.length == 1
    end

    private

    def touch
      return if exist?

      @path.dirname.mkpath
      @path.write('')
    end

    def raise_unless_exists?
      return if exist?

      raise Spellr::Wordlist::NotFound, "Wordlist file #{@file} doesn't exist at #{@path}"
    end
  end
end

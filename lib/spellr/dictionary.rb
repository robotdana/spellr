# frozen_string_literal: true

require 'pathname'
require 'net/http'
require 'set'

module Spellr
  class Dictionary
    DEFAULT_DIR = Pathname.new(__FILE__).parent.parent.parent.join('dictionaries')

    include Enumerable

    attr_accessor :download_required, :downloader, :file, :name, :extensions, :hashbangs, :filenames
    alias_method :download_required?, :download_required
    attr_reader :found_words, :missed_words

    def initialize(file)
      @file = Pathname.new(file).expand_path
      @name = @file.basename('.*').to_s
      @download_options = {}
      @extensions = []
      @filenames = []
      @hashbangs = []
      @found_words = Set.new
      @missed_words = Set.new
    end

    def each(&block)
      download if !file.exist? && download_required?

      file.each_line(&block)
    end

    def include?(term)
      term = term.to_s.downcase + "\n"
      return true if found_words.include?(term)
      return false if missed_words.include?(term)

      if to_set.include?(term)
        found_words << term
        true
      else
        missed_words << term
        false
      end
    end

    def to_set
      @to_set ||= super
    end

    def lazy_download(**download_options)
      self.downloader = Spellr::SCOWLDownloader.new(download_options)
      self.download_required = true
    end

    def download(**download_options)
      self.downloader ||= Spellr::SCOWLDownloader.new(download_options)
      self.download_required = false
      downloader.download(to: file)
      self.downloader = nil

      process_wordlist
    end

    private

    def process_wordlist # rubocop:disable Metrics/AbcSize
      wordlist = file.each_line.map do |line|
        line = line.strip.downcase.sub(/'s$/, '')
        next unless line.length >= Spellr.config.minimum_dictionary_entry_length

        line
      end.compact.uniq.sort

      file.write(wordlist.join("\n") + "\n")
    end
  end
end

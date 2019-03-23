require 'pathname'
require 'net/http'

module Spellr
  class Dictionary
    DEFAULT_DIR = Pathname.new(__FILE__).parent.parent.parent.join('dictionaries')

    include Enumerable

    attr_accessor :download_required, :download_options, :file, :name, :only, :only_hashbangs
    alias_method :download_required?, :download_required

    def initialize(file)
      @file = Pathname.new(file).expand_path
      @name = @file.basename('.*')
      @download_options = {}
      @only = []
      @only_hashbangs = []
    end

    def each(&block)
      enumerator.rewind
      enumerator.each(&block)
    end

    def lazy_download(**download_options)
      self.download_required = true
      self.download_options = download_options
    end

    def download(options = download_options)
      self.download_required = false
      uri = URI.parse('http://app.aspell.net/create')
      uri.query = URI.encode_www_form(
        diacritic: :strip,
        max_size: 50,
        spelling: :US,
        max_variant: 0,
        special: :hacker,
        **options,
        download: :wordlist,
        encoding: 'utf-8',
        format: :inline,
      )

      license, wordlist = Net::HTTP.get_response(uri).body.split('---', 2)
      file.write(wordlist)
      file.sub_ext('.LICENSE.txt').write(license)
      process_wordlist
    end

    private

    def process_wordlist
      wordlist = file.each_line.map do |line|
        line = line.strip.downcase.sub(/'s$/, '')
        next unless line.length >= Spellr.config.minimum_dictionary_entry_length
        line
      end.compact.sort.uniq

      file.write(wordlist.join("\n") + "\n")
    end

    def enumerator
      download if !file.exist? && download_required?
      @enumerator ||= file.each_line.lazy
    end
  end
end

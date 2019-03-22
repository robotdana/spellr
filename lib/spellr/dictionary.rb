require 'pathname'
require 'net/http'

module Spellr
  class Dictionary
    include Enumerable

    attr_accessor :download_required, :download_options, :file, :name
    alias_method :download_required?, :download_required

    def initialize(file)
      @file = file.is_a?(Pathname) ? file : Pathname.new(file)
      @name = @file.basename('.*')
      @download_options = {}
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
        **options,
        download: :wordlist,
        encoding: 'utf-8',
        format: :inline
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
        next unless line.length > 2 # why 2 letter words. You are unnecessary
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

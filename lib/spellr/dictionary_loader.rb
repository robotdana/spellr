require 'net/http'
require 'uri'

module Spellr
  module DictionaryLoader
    module_function

    def download
      uri = URI.parse('http://app.aspell.net/create')
      uri.query = URI.encode_www_form(
        max_size: 50,
        spelling: %w{US AU},
        max_variant: 0,
        diacritic: :both,
        special: :hacker,
        download: :wordlist,
        encoding: 'utf-8',
        format: :inline
      )

      license, wordlist = Net::HTTP.get_response(uri).body.split('---', 2)
      dictionary = Spellr::Dictionary['natural']
      dictionary.file.write(preprocess_entries(wordlist))
      dictionary.license_file.write(license)
    end

    def preprocess_entries(wordlist)
      wordlist.split("\n").map do |line|
        line.downcase! # only compare lowercase. It'll be easier
        line.sub!(/'s$/, '') # exclude possessive
        next unless line.length > 2 # why 2 letter words. You are unnecessary
        line
      end.compact.sort.uniq.join("\n")
    end
  end
end

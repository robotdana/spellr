require 'pathname'
require 'net/http'

module Spellr
  class Dictionary
    DATA_PATH = Pathname.new(__FILE__).join('..', '..', '..', 'data')
    def self.download
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

      license, dictionary = Net::HTTP.get_response(uri).body.split('---', 2)
      DATA_PATH.join('DICTIONARY').write(preprocess_entries(dictionary))
      DATA_PATH.join('LICENSE').write(license)
    end

    def self.preprocess_entries(dictionary)
      dictionary.split("\n").map do |line|
        line.downcase! # only compare lowercase. It'll be easier
        line.sub!(/'s$/, '') # why
        next unless line.length > 2 # why 2 letter words. You are unnecessary
        line
      end.compact.sort.uniq.join("\n")
    end
  end
end

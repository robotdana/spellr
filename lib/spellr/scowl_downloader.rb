# frozen_string_literal: true

module Spellr
  class SCOWLDownloader
    def initialize(
      max_size: 50,
      spelling: :US,
      max_variant: 0,
      diacritic: :both,
      hacker: true
    )
      @options = {}
      @options[:max_size] = max_size.to_i
      @options[:spelling] = Array(spelling).map(&:to_sym).uniq
      @options[:max_variant] = max_variant
      @options[:diacritic] = diacritic.to_sym
      @options[:special] = :hacker if hacker
    end

    def download(to:)
      file = Pathname.new(to)
      license, wordlist = Net::HTTP.get_response(uri).body.split('---', 2)
      file.write(wordlist)
      file.sub_ext('.LICENSE.txt').write(license)
    end

    private

    attr_reader :options

    def valid?
      max_size_valid? && max_variant_valid? && diacritic_valid? && spelling_valid?
    end

    def max_size_valid?
      [10, 20, 35, 40, 50, 55, 60, 70, 80, 95].include?(options[:max_size])
    end

    def max_variant_valid?
      (0..3).cover?(options[:max_variant])
    end

    def diacritic_valid?
      %i{strip keep both}.include?(options[:diacritic])
    end

    def spelling_valid?
      (options[:spelling] - %i{US GBs GBz CA AU}).empty?
    end

    def uri
      query = URI.encode_www_form(
        **options,
        download: :wordlist,
        encoding: :'utf-8',
        format: :inline
      )
      URI.parse("http://app.aspell.net/create?#{query}")
    end
  end
end

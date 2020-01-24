#!/usr/bin/env ruby

# frozen_string_literal: true

require 'net/http'
require 'nokogiri'
require 'json'
require 'parallel'
require_relative 'write'
require_relative 'fetch'
require_relative '../../../lib/spellr/string_format'

class MDNWords # rubocop:disable Metrics/ClassLength
  include Write
  include Fetch
  include Spellr::StringFormat

  HOST = 'wiki.developer.mozilla.org'

  def initialize(wordlist, paths, # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
    sections: [],
    additional_words: [],
    additional_license: '',
    exclude_proc: ->(_) { false })
    @paths = paths
    @mutex = Mutex.new
    @wordlist = wordlist
    @additional_words = additional_words
    @additional_license = additional_license
    @sections = sections
    @exclude_proc = exclude_proc
    run
  end

  def run
    words = @additional_words
    words_and_paths = Parallel.map(@paths, in_threads: 2) { |p| keywords_from_path(p) }
    words += words_and_paths.map(&:values).flatten

    write_wordlist(words.join("\n"), @wordlist)
    write_license(words_and_paths.flat_map(&:keys))
  end

  def base_uri(path)
    uri = to_uri(path)
    uri.query = nil
    uri.fragment = nil
    uri
  end

  def to_uri(path)
    uri = URI.parse(path.to_s)
    uri.host = HOST
    uri.scheme = 'https'
    URI.parse(uri.to_s) # force it to be a URI::HTTPS so Net::HTTP can deal with it wtf ruby.
  end

  def license_for_uri(uri) # rubocop:disable Metrics/MethodLength
    json_uri = base_uri(uri)
    json_uri.path += '$json'
    # puts "generating license string for #{uri}"
    response = fetch(json_uri, uri_proc: method(:to_uri))

    return '' if response.empty?

    json_page = JSON.parse(response)
    # puts "completing license for #{uri}"
    license_string(json_page['title'], base_uri(json_page['url']))
  rescue URI::InvalidURIError
    warn(red("#{uri} is not a valid uri"))
    ''
  end

  def license_string(title, path)
    "[#{title}](#{path}) by [Mozilla Contributors](#{path}$history)" \
      " is licensed under [CC-BY-SA 2.5](http://creativecommons.org/licenses/by-sa/2.5/)\n"
  end

  def write_license(paths) # rubocop:disable Metrics/MethodLength
    license = Parallel.map(paths, in_threads: 20) do |u|
      license_for_uri(u)
    end

    license = "# keywords & values are from these sources: \n\n#{license.sort.uniq.join}"
    license += "\n#{@additional_license}"
    wordlist_path("#{@wordlist}.LICENSE").sub('.txt', '.md').write(license)
  end

  def keywords_from_path(path) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    uri = to_uri(path)

    # puts "fetching #{uri}"
    response = fetch(uri, uri_proc: method(:to_uri))

    return {} if response.empty?

    document = Nokogiri::HTML.parse(response)
    words = values_from_document(document)
    paths = document
      .xpath('//a[not(@class) and code[not(@class)] and not(ancestor::div/@class="Quick_links")]')
      .map { |x| x[:href] }.select { |x| x.to_s.start_with?('/') }
    # puts "completing #{uri}"
    values_and_paths = values_from_paths(paths)
    values_and_paths.merge(uri.to_s => words)
  rescue URI::InvalidURIError
    warn red("#{path} is not a valid uri")
    {}
  end

  def values_from_document(document)
    document.xpath('//code[not(ancestor::pre)] | //dt').map(&:content).reject(&@exclude_proc)
  end

  def values_from_paths(paths) # rubocop:disable Metrics/MethodLength
    uris = paths.map do |p|
      base_uri(p)
    rescue URI::InvalidURIError
      puts red("#{p} is not a valid uri")
      nil
    end.uniq.compact

    Parallel.map(uris, in_threads: 10) do |u|
      words = values_from_uri(u)
      next unless words

      [u.to_s, words]
    end.compact.to_h
  end

  def values_from_uri(uri) # rubocop:disable Metrics/MethodLength
    response = ''
    @sections.each do |section|
      uri.query = "raw&macros&section=#{section}"
      # puts "fetching #{uri}"
      response = fetch(uri, uri_proc: method(:to_uri))
      break unless response.empty?
    end

    if response.empty?
      uri.query = 'raw&macros'
      warn red("can't load section from #{uri}")
      return
    end

    document = Nokogiri::HTML.parse(response)

    # puts "completing #{uri}"
    words = values_from_document(document)

    if words.empty?
      warn(red("can't find values for #{uri}\n") + response)
      return
    end

    words
  end
end

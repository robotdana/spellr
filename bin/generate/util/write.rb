# frozen_string_literal: true

require 'pathname'
require_relative '../../../lib/spellr/wordlist'

module Write
  OUTPUT_DIR = Pathname.new(
    ENV['SPELLR_TEST_PWD'] || File.expand_path('../../..', __dir__)
  ).join('wordlists')

  def wordlist_path(name)
    OUTPUT_DIR.join("#{name}.txt")
  end

  def write_wordlist(words, name)
    wordlist_path(name).parent.mkpath
    Spellr::Wordlist.new(wordlist_path(name)).clean(StringIO.new(words.force_encoding('UTF-8')))
  end

  def append_wordlist(words, name)
    old_words = wordlist_path(name).read if wordlist_path(name).exist?
    write_wordlist("#{words}\n#{old_words}".dup, name)
  end

  def license_path(name, ext = '.txt')
    wordlist_path(name).sub_ext(".LICENSE#{ext}")
  end

  def write_license(license, name, ext = '.txt')
    license_path(name).parent.mkpath
    license_path(name, ext).write(license)
  end
end

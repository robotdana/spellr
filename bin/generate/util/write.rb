# frozen_string_literal: true

require 'pathname'
require_relative '../../../lib/spellr/wordlist'

module Write
  OUTPUT_DIR = Pathname.new(__dir__).join('..', '..', '..', 'wordlists')

  def wordlist_path(name)
    OUTPUT_DIR.join("#{name}.txt")
  end

  def write_wordlist(words, name)
    Spellr::Wordlist.new(wordlist_path(name)).clean(StringIO.new(words.force_encoding('UTF-8')))
  end

  def append_wordlist(words, name)
    old_words = wordlist_path(name).read
    write_wordlist("#{words}\n#{old_words}", name)
  end
end

# frozen_string_literal: true

require 'pathname'
require_relative '../../lib/spellr/wordlist/wordlist'

module Generate
  OUTPUT_DIR = Pathname.new(__dir__).join('..', '..', 'wordlists')

  def wordlist_path(name)
    OUTPUT_DIR.join("#{name}.txt")
  end

  def write_wordlist(words, name)
    Spellr::Wordlist.new(wordlist_path(name)).clean(StringIO.new(words.force_encoding('UTF-8')))
  end
end

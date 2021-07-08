# frozen_string_literal: true

require_relative '../spellr'
require_relative 'check'

module Spellr
  class CheckInteractive < Check
    private

    def check_file_from_restart(file, restart_token, wordlist_set)
      # new wordlist cache when adding a word
      wordlist_set = Spellr::WordlistSet.for_file(file) unless restart_token.replacement
      check_file(file, restart_token.location, wordlist_set)
    end

    def check_file(file, start_at = nil, wordlist_set = Spellr::WordlistSet.for_file(file))
      restart_token = catch(:check_file_from) do
        super(file, start_at, wordlist_set)
        nil
      end
      check_file_from_restart(file, restart_token, wordlist_set) if restart_token
    end
  end
end

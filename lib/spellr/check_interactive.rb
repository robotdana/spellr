# frozen_string_literal: true

require_relative '../spellr'
require_relative 'check'

module Spellr
  class CheckInteractive < Check
    private

    def check_file_from_restart(file, restart_token, wordlist_proc)
      # new wordlist cache when adding a word
      wordlist_proc = wordlist_proc_for(file) unless restart_token.replacement
      check_file(file, restart_token.location, wordlist_proc)
    end

    def check_file(file, start_at = nil, wordlist_proc = wordlist_proc_for(file))
      restart_token = catch(:check_file_from) do
        super(file, start_at, wordlist_proc)
        nil
      end
      check_file_from_restart(file, restart_token, wordlist_proc) if restart_token
    end
  end
end

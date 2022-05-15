# frozen_string_literal: true

begin
  require_relative 'suggester'
  # :nocov:
rescue LoadError
  require_relative 'null_suggester'
  Spellr::Suggester = Spellr::NullSuggester
  # :nocov:
end

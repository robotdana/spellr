require_relative "spellr/version"
require_relative "spellr/token"
require_relative "spellr/line"
require_relative "spellr/files"
require_relative "spellr/dictionary"
require_relative "spellr/dictionary_loader"

module Spellr
  class Error < StandardError; end
end

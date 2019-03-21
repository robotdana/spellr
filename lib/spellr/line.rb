module Spellr
  class Line
    attr_reader :line
    # Finds everything that is either a word,
    # Or we might need it for proving something isn't a word
    # in additional to [[:alpha:]], for testing if they're
    SCAN_RE = %r{
      (?:
        [[[:alpha:]]\#\\=/\-0-9]
        # inside URL or starting colour code
        # escape codes maybe
        # base64
      |
        (?<!\s)[%&._@+=/\-?](?!\s) # inside a URL
      |
        \:((?=//)|(?<=mailto:)) # colon in a URL or mailto link
      |
        (?<!\\033)(?<!\\e)\[ # shell escape codes
      |
        (?<=[[[:alpha:]]])'(?=[[[:alpha:]]]) # apostrophes
      ){3,} # no short words
    }x

    def initialize(line)
      @line = line
    end

    def tokenize
      tokens = []
      line.scan(SCAN_RE) do
        tokens += Token.new(Regexp.last_match).tokens
      end
      tokens
    end
  end
end

require 'uri'
module Spellr
  class Token
    STRIP_START = %r{^[^\\#[[:alpha:]]]+}
    STRIP_END = %r{[^[[:alpha:]]]+$}
    SUBTOKEN_RE = %r{
      [[[:alpha:]]']+
    }x

    attr_reader :string, :start, :end
    def initialize(match, offset: 0)
      @string = match[0]
      @start = match.begin(0) + offset
      @end = match.end(0) + offset

      strip_start
      strip_end
    end

    def strip_start
      new_string = @string.sub(STRIP_START, '')
      @start += @string.length - new_string.length
      @string = new_string
    end

    def strip_end
      new_string = @string.sub(STRIP_END, '')
      @end -= @string.length - new_string.length
      @string = new_string
    end

    def to_s
      @string
    end

    def url?
      !URI.extract(@string).empty?
    end

    def hex?
      @string =~ /#(\h{6}|\h{3})/
    end

    def word?
      return if @string.empty?
      return if @string.length <= 2
      return if url?
      return if hex?
      true
    end

    def tokens
      return [] unless word?
      t = []
      string.scan(SUBTOKEN_RE) { t << Token.new(Regexp.last_match, offset: @start)  }
      t.select(&:word?)
    end
  end
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
        (?<!\s)[%&._@+=\-](?!\s) # inside a URL
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

require 'uri'
module Spellr
  class Token
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

    STRIP_START = %r{^[^\\/#[[:alpha:]]]+}
    STRIP_END = %r{[^[[:alpha:]]]+$}
    SUBTOKEN_RE = %r{(
      (?<![[:upper:]])[[[:lower:]]']+(?<!'s) # lowercase not preceded by uppercase
      |
      [[[:upper:]]']+(?<!'S)(?![[:lower:]]) # uppercase not succeeded by lowercase
      |
      [[:upper:]][[[:lower:]]']+(?<!'s) # camel case like CaseCase
      |
      [[[:upper:]]']+(?<!'S)(?=[[:upper:]][[:lower:]]) # camel case like CASECase
    )}x

    def self.tokenize(line)
      tokens = []
      line.scan(SCAN_RE) do
        tokens += Token.new(Regexp.last_match, line: line).tokens
      end
      tokens
    end

    attr_reader :string, :start, :end, :line
    def initialize(match, offset: 0, line:)
      @line = line
      @string = match[0]
      @start = match.begin(0) + offset
      @end = match.end(0) + offset

      strip_start
      strip_end
    end

    def file
      line.file
    end

    def before
      line.slice(0...start)
    end

    def after
      line.slice(@end..-1)
    end

    def location
      [line.location, start].compact.join(':')
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
      return true unless URI.extract(@string).empty?
      # URI with no scheme
      return true if @string.start_with?('//') && !URI.extract("http:#{@string}").empty?
      return true if @string.include?('@') && !URI.extract("mailto:#{@string}").empty?
    end

    def hex?
      @string =~ /(#|0x)(\h{6}|\h{3})/
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
      string.scan(SUBTOKEN_RE) { t << Token.new(Regexp.last_match, offset: @start, line: line)  }
      t.select(&:word?)
    end
  end
end

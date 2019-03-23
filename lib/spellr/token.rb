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
      )+
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
      line.to_s.scan(SCAN_RE) do
        m = Regexp.last_match
        t = Token.new(m[0], start: m.begin(0), line: line)
        t.strip!
        tokens += t.tokens
      end
      tokens
    end

    attr_reader :string, :start, :end, :line
    def initialize(string, start: 0, line: nil)
      @line = line
      @string = string
      @start = start
    end

    def file
      line.file
    end

    def before
      line.slice(0...start)
    end

    def after
      line.slice(self.end..-1)
    end

    def end
      start + string.length
    end

    def location
      [line.location, start].compact.join(':')
    end

    def strip!
      new_string = string.sub(STRIP_START, '')
      @start += @string.length - new_string.length
      @string = new_string.sub(STRIP_END, '')
    end

    def to_s
      string
    end

    def url?
      return true unless URI.extract(@string).empty?
      # URI with no scheme
      return true if string.start_with?('//') && !URI.extract("http:#{@string}").empty?
      return true if string.include?('@') && !URI.extract("mailto:#{@string}").empty?
    end

    def hex?
      string =~ /\A(#|0x)(\h{6}|\h{3})\z/
    end

    def inspect
      "Token(#{string})"
    end

    def word?
      return if string.empty?
      return if string.length < Spellr.config.word_minimum_length
      return if url?
      return if hex?
      true
    end

    def to_str
      string
    end

    def ==(other)
      return string == other if other.is_a?(String)

      super
    end

    def tokens
      return [] unless word?
      t = []
      string.scan(SUBTOKEN_RE) do
        m = Regexp.last_match
        tt = Token.new(m[0], start: start + m.begin(0), line: line)
        tt.strip!
        t << tt
      end
      t.select(&:word?)
    end

    def subwords(include_self: false, depth: Spellr.config.subword_maximum_count)
      min_length = Spellr.config.subword_minimum_length
      base = include_self ? [[self]] : []
      return base unless min_length * 2 <= string.length || depth == 1
      base + (min_length..(string.length - min_length)).flat_map do |first_part_length|
        first_part = Token.new(string.slice(0, first_part_length), start: start, line: line)
        Token.new(string.slice(first_part_length..-1), start: start + first_part_length, line: line).subwords(include_self: true, depth: depth - 1).map do |t|
          [first_part, *t.flatten]
        end
      end
    end
  end
end

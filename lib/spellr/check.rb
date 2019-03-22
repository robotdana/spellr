module Spellr
  class Check
    attr_reader :exit_code

    def initialize(files:, interactive: false, reporter: Spellr::Reporter)
      @files = files
      @reporter = reporter
      @exit_code = 0
    end

    def check
      each_token do |token|
        token_string = token.to_s.downcase + "\n"
        next if Spellr.config.dictionaries.any? do |dict|
          dict.include?(token_string)
        end
        reporter.report(token)
        @exit_code = 1
      end
    end

    private

    attr_reader :files, :reporter

    def each_line(&block)
      files.each do |file|
        file.each_line.with_index do |line, index|
          block.call(Spellr::Line.new(line, file: file, line_number: index + 1))
        end
      end
    end

    def each_token(&block)
      each_line do |line|
        line.tokenize.each(&block)
      end
    end
  end
end

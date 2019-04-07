# frozen_string_literal: true

module Spellr
  class Check
    attr_reader :exit_code
    attr_reader :files, :reporter

    def initialize(files: [], reporter: Spellr.config.reporter)
      @files = files
      @reporter = reporter
      @exit_code = 0
    end

    def check
      files.each do |file|
        check_file(file)
      rescue ArgumentError => error
        # sometimes files are binary
        if /invalid byte sequence/.match?(error.message)
          puts "Skipped invalid file: #{file}"
          next
        end

        raise
      end
    end

    private

    def check_file(file)
      file.each_line.with_index do |line, _index|
        Spellr::Tokenizer.new(line).each do |token, _pos|
          next if file.dictionaries.any? { |d| d.include?(token) }

          reporter.call(Spellr::Token.new(token, file: file, line: line, line_number: index + 1, start: pos))
          @exit_code = 1
        end
      end
    end
  end
end

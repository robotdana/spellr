module Spellr
  class Check
    attr_reader :exit_code

    def initialize(files:, interactive: false, reporter: Spellr::Reporter)
      @files = files
      @reporter = reporter
      @exit_code = 0
    end

    def check
      files.each do |file|
        file.each_line do |line|
          line.each_token do |token|
            token_string = token.to_s.downcase + "\n"

            next if token.file.dictionaries.any? { |d| d.include?(token_string) }

            reporter.report(token)
            @exit_code = 1
          end
        end
      end
    end

    private

    attr_reader :files, :reporter
  end
end

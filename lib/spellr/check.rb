module Spellr
  class Check
    attr_reader :exit_code

    def initialize(files:, reporter: Spellr.config.reporter)
      @files = files
      @reporter = reporter
      @exit_code = 0
    end

    def check
      files.each do |file|
        file.each_token do |token|
          next if check_token(token, file.dictionaries)

          reporter.report(token)
          @exit_code = 1
        end
      end
    end

    private

    def check_token(token, dictionaries)
      token_string = token.to_s.downcase + "\n"

      return true if dictionaries.any? { |d| d.include?(token_string) }

      return true if Spellr.config.run_together_words? && token.subwords.any? do |subword_set|
        subword_set.all? do |subword|
          subword_string = subword.to_s.downcase + "\n"
          dictionaries.any? { |d| d.include?(subword_string) }
        end
      end
    end

    attr_reader :files, :reporter
  end
end

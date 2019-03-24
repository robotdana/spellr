require 'pathname'
require 'gitignore/parser'

module Spellr
  class File
    attr_reader :file

    def initialize(name)
      @file = Pathname.new(name).expand_path
    end



    def dictionaries
      @dictionaries ||= Spellr.config.dictionaries.values.select do |dict|
        fn_match?(dict.only) || hashbang_match?(dict.only_hashbangs)
      end
    end

    def fn_match?(matches)
      return true if matches.empty?
      matches = matches.map { |match| "*/#{match}" }
      match_string = matches.first if matches.length == 1
      match_string ||= "{#{matches.join(',')}}"

      file.fnmatch?(match_string, ::File::FNM_DOTMATCH | ::File::FNM_EXTGLOB)
    end

    def hashbang_match?(matches)
      return false if matches.empty?
      return false if file.extname != ''

      first_line = file.each_line.lazy.first
      return false unless first_line.start_with?("#!")

      matches.any? { |match| first_line.include?(match) }
    end

    def to_s
      file.to_s
    end

    def ==(other)
      return to_s == other if other.respond_to?(:to_str)

      super
    end

    def each_line(&block)
      file.each_line.lazy.with_index do |line_string, line_number|
        line = Spellr::Line.new(line_string, file: self, line_number: line_number)

        block.call line
      end
    end

    def each_token(&block)
      each_line do |line|
        line.each_token(&block)
      end
    end
  end
end

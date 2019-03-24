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
        dict.only.empty? ||
          dict.file_list.bsearch { |value| file <=> value } ||
          (hashbang && dict.only_hashbangs.any? { |match| hashbang.include?(match) })
      end
    end

    def hashbang
      return if file.extname != ''
      return unless first_line.start_with?("#!")

      first_line
    end

    def first_line
      @first_line ||= file.each_line.first
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
        line = Spellr::Line.new(line_string)

        block.call line, line_number
      end
    end
  end
end

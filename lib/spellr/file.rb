# frozen_string_literal: true

require 'pathname'

module Spellr
  class File < Pathname
    def self.wrap(file)
      file.is_a?(Spellr::File) ? file : Spellr::File.new(file)
    end

    # don't use FastIgnore shebang handling
    # because i use lots of different FastIgnore instances and each would to open the files.
    def hashbang
      @hashbang ||= begin
        return if extname != ''
        return unless first_line&.start_with?('#!')

        first_line
      end
    end

    def first_line
      @first_line ||= each_line.first
    end

    def relative_path
      @relative_path ||= relative_path_from(Spellr.config.pwd)
    end

    def insert(string, range)
      read_write do |body|
        body[range] = string
        body
      end
    end

    def read_write
      write(yield read)
    end
  end
end

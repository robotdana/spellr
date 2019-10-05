# frozen_string_literal: true

require 'pathname'

# TODO: maybe just extend pathname if you have to

module Spellr
  class File < Pathname
    def self.wrap(file)
      file.is_a?(Spellr::File) ? file : Spellr::File.new(file)
    end

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
  end
end

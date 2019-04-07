# frozen_string_literal: true

require 'pathname'

module Spellr
  class File < Pathname
    def hashbang
      return if extname != ''
      return unless first_line.start_with?('#!')

      first_line
    end

    def first_line
      @first_line ||= each_line.first
    end
  end
end

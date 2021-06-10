# frozen_string_literal: true

require 'pathname'

module Spellr
  class File < Pathname
    def relative_path
      @relative_path ||= relative_path_from(Spellr.pwd)
    end

    def insert(string, range)
      read_write do |body|
        body[range] = string
        body
      end
    end

    # the bulk of this method is copied from fast_ignore
    def first_line # rubocop:disable Metrics/MethodLength
      return @first_line if defined?(@first_line)

      @first_line = nil

      file = ::File.new(to_s)
      @first_line = file.sysread(25)
      @first_line += file.sysread(50) until @first_line.include?("\n")
      file.close
      @first_line
    rescue ::EOFError, ::SystemCallError
      # :nocov:
      file&.close
      # :nocov:
      @first_line
    end

    def read_write
      write(yield(read(encoding: ::Encoding::UTF_8)), encoding: ::Encoding::UTF_8)
    end
  end
end

# frozen_string_literal: true

class Array
  unless RUBY_VERSION >= '2.4'
    def sum
      if block_given?
        reduce(0) { |total, value| total + yield(value) }
      else
        reduce(:+)
      end
    end
  end
end

class Regexp
  alias_method :match?, :match unless RUBY_VERSION >= '2.4'
end

class String
  alias_method :match?, :match unless RUBY_VERSION >= '2.4'
end

class Hash
  unless RUBY_VERSION >= '2.5'
    def slice!(*keys)
      delete_if { |k| !keys.include?(k) }
    end

    def slice(*keys)
      dup.slice!(*keys)
    end
  end
end

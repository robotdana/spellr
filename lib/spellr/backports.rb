# frozen_string_literal: true

ruby_version = Gem::Version.new(RUBY_VERSION)

unless ruby_version >= Gem::Version.new('2.4')
  class Array
    def sum
      if block_given?
        reduce(0) { |total, value| total + yield(value) }
      else
        reduce(0, :+)
      end
    end
  end

  class Regexp
    alias_method :match?, :match
  end

  class String
    alias_method :match?, :match
  end
end

unless ruby_version >= Gem::Version.new('2.5')
  class Hash
    def slice!(*keys)
      delete_if { |k| !keys.include?(k) }
    end

    def slice(*keys)
      dup.slice!(*keys)
    end
  end
end

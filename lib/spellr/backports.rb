# frozen_string_literal: true

class Array
  unless RUBY_VERSION >= '2.4'
    def sum
      reduce(0) do |total, value|
        total + if block_given?
          yield value
        else
          value
        end
      end
    end
  end
end

class String
  alias_method :match?, :match unless RUBY_VERSION >= '2.4'
end

# frozen_string_literal: true

module Spellr
  class StringIOWithEncoding < ::StringIO
    def each_line(*args, encoding: nil, **kwargs, &block)
      string.force_encoding(encoding) if encoding && !string.frozen?

      super(*args, **kwargs, &block)
    end
  end
end

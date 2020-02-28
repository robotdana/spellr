# frozen_string_literal: true

module Spellr
  module Validations
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def validations
        @validations ||= []
      end

      def validate(method)
        validations << method
      end
    end

    def valid?
      self.class.validations.each do |validation|
        send(validation)
      end

      errors.empty?
    end

    def errors
      @errors ||= []
    end
  end
end

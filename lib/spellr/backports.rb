# frozen_string_literal: true

module Spellr
  unless Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.6')
    require 'yaml'
    module YAMLPermittedClasses
      refine YAML.singleton_class do
        alias_method :safe_load_without_permitted_classes, :safe_load
        def safe_load(path, *args, permitted_classes: nil, **kwargs)
          if permitted_classes
            safe_load_without_permitted_classes(path, permitted_classes, *args, **kwargs)
          else
            safe_load_without_permitted_classes(path, *args, **kwargs)
          end
        end
      end
    end
  end
end

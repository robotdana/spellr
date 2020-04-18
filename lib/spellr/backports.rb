# frozen_string_literal: true

module Spellr
  ruby_version = Gem::Version.new(RUBY_VERSION)
  unless ruby_version >= Gem::Version.new('2.5')
    module HashSlice
      refine Hash do
        def slice!(*keys)
          delete_if { |k| !keys.include?(k) }
        end

        def slice(*keys)
          dup.slice!(*keys)
        end
      end
    end

    require 'yaml'
    module YAMLSymbolizeNames
      refine YAML.singleton_class do
        alias_method :safe_load_without_symbolize_names, :safe_load
        def safe_load(path, *args, symbolize_names: false, **kwargs)
          if symbolize_names
            symbolize_names!(safe_load_without_symbolize_names(path, *args, **kwargs))
          else
            safe_load_without_symbolize_names(path, *args, **kwargs)
          end
        end

        private

        def symbolize_names!(obj) # rubocop:disable Metrics/MethodLength
          case obj
          when Hash
            obj.keys.each do |key| # rubocop:disable Style/HashEachMethods # each_key never finishes.
              obj[key.to_sym] = symbolize_names!(obj.delete(key))
            end
          when Array
            obj.map! { |ea| symbolize_names!(ea) }
          end
          obj
        end
      end
    end
  end

  unless ruby_version >= Gem::Version.new('2.6')
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

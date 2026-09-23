# frozen_string_literal: true

module Nokogiri
  module CSS
    module SelectorCache # :nodoc:
      @cache = {}
      @mutex = Mutex.new

      class << self
        # Retrieve the cached XPath expressions for the key
        def [](key)
          return ractor_local_cache[key] unless main_ractor?

          @mutex.synchronize { @cache[key] }
        end

        # Insert the XPath expressions `value` at the cache key
        def []=(key, value)
          return ractor_local_cache[key] = value unless main_ractor?

          @mutex.synchronize { @cache[key] = value }
        end

        # Clear the cache
        def clear_cache(create_new_object = false)
          return ractor_local_cache.clear unless main_ractor?

          @mutex.synchronize do
            if create_new_object # used in tests to avoid 'method redefined' warnings when injecting spies
              @cache = {}
            else
              @cache.clear
            end
          end
        end

        # Construct a unique key cache key
        def key(selector:, visitor:)
          [selector, visitor.config]
        end

        private

        def main_ractor?
          !defined?(Ractor) || Ractor.current == Ractor.main
        end

        # Non-main Ractors can't access @cache or @mutex, so they each keep their own cache.
        def ractor_local_cache
          Ractor.current[:__nokogiri_css_selector_cache] ||= {}
        end
      end
    end
  end
end

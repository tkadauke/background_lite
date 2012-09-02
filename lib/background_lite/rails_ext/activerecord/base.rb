module ActiveRecord
  class Base
    # Override this method to strip your object from data that doesn't have to
    # be transmitted to the background process. Note that you don't need to
    # clear the association cache, as this is already done for you in
    # clone_for_background.
    def cleanup_for_background
    end
    
    # Prepares the object to be transmitted to the background. This method dups
    # the object and strips some instance variables, most notably the
    # association cache, in order to prevent all associations to be transmitted
    # with the object in full length.
    #
    # To clean up data specific to your class, use cleanup_for_background.
    def clone_for_background
      dup.tap do |x|
        x.cleanup_for_background
        
        # taken from ActiveRecord::AttributeMethods::ATTRIBUTE_TYPES_CACHED_BY_DEFAULT
        type_to_preserve = [DateTime, Time, Date]
        attr_cache = x.instance_variable_get(:@attributes_cache)
        attr_cache.each do |key, value|
          attr_cache[key] = nil unless type_to_preserve.include?(attr_cache[key].class)
        end
        x.instance_variable_set(:@errors, nil)
        x.clear_association_cache
      end
    end
  end
end

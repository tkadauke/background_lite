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
      returning dup do |x|
        x.cleanup_for_background
        x.instance_variable_set(:@attributes_cache, nil)
        x.instance_variable_set(:@errors, nil)
        x.clear_association_cache
      end
    end
  end
end

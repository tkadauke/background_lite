module ActiveRecord
  class Base
    def cleanup_for_background
    end
    
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

module BackgroundLite
  # This handler is used in a testing environment. It allows for introspection
  # of last call to the handle method.
  class TestHandler
    # contains the object on which the method is executed.
    cattr_accessor :object
    # contains the method name to execute
    cattr_accessor :method
    # contains the method's arguments
    cattr_accessor :args
    # If true, the execution of TestHandler#handle will fail the next time it's
    # called.
    cattr_accessor :fail_next_time
    # True, if TestHandler#handle was executed.
    cattr_accessor :executed
    # Stores the last options hash given to handle
    cattr_accessor :options
    
    # Does not call the block, but sets some variables for introspection.
    def self.handle(object, method, args, options = {})
      self.executed = true
      if self.fail_next_time
        self.fail_next_time = false
        raise "TestHandler.handle: Failed on purpose"
      end
      
      self.object, self.method, self.args, self.options = object, method, args, options
    end
    
    # Resets the class' accessors.
    def self.reset
      object = method = args = options = fail_next_time = executed = nil
    end
  end
end

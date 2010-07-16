module BackgroundLite
  # This background handler sends the method as well as the arguments through
  # Resque to the background process.
  class ResqueHandler
    @queue = :background
    
    # Marshals the method and the arguments and sends it through Resque
    # to the background process.
    def self.handle(object, method, args, options = {})
      require 'resque'
      Resque.enqueue(self, Base64.encode64(Marshal.dump([object, method, args])))
    end
    
    # Decodes a marshalled message which was previously sent over
    # Resque. Returns an array containing the object, the method name
    # as a string, and the method arguments.
    def self.decode(message)
      begin
        object, method, args = Marshal.load(Base64.decode64(message))
      rescue ArgumentError => e
        # Marshal.load does not trigger const_missing, so we have to do this
        # ourselves.
        e.message.split(' ').last.constantize
        retry
      end
      [object, method, args]
    end
    
    # Executes a marshalled message which was previously sent over
    # Resque, in the context of the object, with all the arguments
    # passed.
    def self.perform(message)
      begin
        object, method, args = self.decode(message)
        puts "--- executing method: #{method}\n--- with variables: #{args.inspect}\n--- in object: #{object.class.name}, #{object.id}"

        object.send(method, *args)
        puts "--- it happened!"
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end
  end
end

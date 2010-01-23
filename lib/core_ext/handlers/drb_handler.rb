module BackgroundLite
  # This background handler sends the method as well as the arguments through
  # DRb to the background process.
  class DrbHandler
    def self.background_queue
      @background_queue ||= begin
        require 'drb'
        
        DRb.start_service
        DRbObject.new(nil, "druby://localhost:2251")
      end
    end
    
    # Marshals the method and the arguments and sends it through DRb
    # to the background process.
    def self.handle(object, method, args, options = {})
      background_queue.push(Marshal.dump([object, method, args]))
    end
    
    # Decodes a marshalled message which was previously sent over
    # DRb. Returns an array containing the object, the method name
    # as a string, and the method arguments.
    def self.decode(message)
      begin
        object, method, args = Marshal.load(message)
      rescue ArgumentError => e
        # Marshal.load does not trigger const_missing, so we have to do this
        # ourselves.
        e.message.split(' ').last.constantize
        retry
      end
      [object, method, args]
    end
    
    # Executes a marshalled message which was previously sent over
    # DRb, in the context of the object, with all the arguments
    # passed.
    def self.execute(message)
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

module BackgroundLite
  # This background handler sends the method as well as the arguments through
  # ActiveMessaging to the background poller. If you don't use the
  # ActiveMessaging plugin, then this handler won't work.
  # 
  # To make the background_lite plugin work with ActiveMessaging, you need to
  # put the following processor in app/processors:
  #
  #   class BackgroundProcessor < ApplicationProcessor
  #     subscribes_to :background
  #   
  #     def on_message(message)
  #       puts "BackgroundProcessor"
  #       BackgroundLite::ActiveMessagingHandler.execute(message)
  #     end
  #   end
  class ActiveMessagingHandler
    # The ActiveMessaging queue name through which the message should be
    # serialized.
    @@queue_name = :background
    cattr_accessor :queue_name
    
    # Marshals the method and the arguments and sends it through ActiveMessaging
    # to the background processor.
    #
    # === Options
    #
    # queue:: The name of the queue to use to send the message to the background
    #         process.
    def self.handle(object, method, args, options = {})
      ActiveMessaging::Gateway.publish((options[:queue] || self.queue_name).to_sym, Marshal.dump([object, method, args]))
    end
    
    # Decodes a marshalled message which was previously sent over
    # ActiveMessaging. Returns an array containing the object, the method name
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
    # ActiveMessaging, in the context of the object, with all the arguments
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

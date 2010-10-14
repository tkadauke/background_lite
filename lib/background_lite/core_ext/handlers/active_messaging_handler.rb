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
      ActiveMessaging::Gateway.publish((options[:queue] || self.queue_name).to_sym, Marshal.dump([object, method, args, options[:transaction_id]]))
    end
    
    # Decodes a marshalled message which was previously sent over
    # ActiveMessaging. Returns an array containing the object, the method name
    # as a string, and the method arguments.
    def self.decode(message)
      begin
        object, method, args, transaction_id = Marshal.load(message)
      rescue ArgumentError => e
        # Marshal.load does not trigger const_missing, so we have to do this
        # ourselves.
        e.message.split(' ').last.constantize
        retry
      end
      [object, method, args, transaction_id]
    end
    
    # Executes a marshalled message which was previously sent over
    # ActiveMessaging, in the context of the object, with all the arguments
    # passed.
    def self.execute(message)
      logger = BackgroundLite::Config.default_logger
      begin
        object, method, args, transaction_id = self.decode(message)
        if logger.debug?
          logger.debug "--- executing method: #{method}"
          logger.debug "--- with variables: #{args.inspect}"
          logger.debug "--- in object: #{object.class.name}, #{object.id}"
          logger.debug "--- Transaction ID: #{transaction_id}"
        end
        object.send(method, *args)
        logger.debug "--- it happened!" if logger.debug?
      rescue Exception => e
        logger.fatal e.message
        logger.fatal e.backtrace
        "BackgroundLite::#{BackgroundLite::Config.default_error_reporter.to_s.camelize}ErrorReporter".constantize.report(e)
        raise e
      end
    end
  end
end

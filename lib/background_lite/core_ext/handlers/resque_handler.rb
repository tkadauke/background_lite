module BackgroundLite
  # This background handler sends the method as well as the arguments through
  # Resque to the background process.
  class ResqueHandler
    @queue = :background
   
    class << self
      attr_accessor :queue
    end

    # Marshals the method and the arguments and sends it through Resque
    # to the background process.
    def self.handle(object, method, args, options = {})
      require 'resque'
      Resque.enqueue(self, Base64.encode64(Marshal.dump([object, method, args, options[:transaction_id]])))
    end
    
    # Decodes a marshalled message which was previously sent over
    # Resque. Returns an array containing the object, the method name
    # as a string, and the method arguments.
    def self.decode(message)
      begin
        object, method, args, transaction_id = Marshal.load(Base64.decode64(message))
      rescue ArgumentError => e
        # Marshal.load does not trigger const_missing, so we have to do this
        # ourselves.
        e.message.split(' ').last.constantize
        retry
      end
      [object, method, args, transaction_id]
    end
    
    # Executes a marshalled message which was previously sent over
    # Resque, in the context of the object, with all the arguments
    # passed.
    def self.perform(message)
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

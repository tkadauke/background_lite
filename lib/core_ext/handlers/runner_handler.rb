require 'base64'

module BackgroundLite
  # This background handler runs the method block via script/runner.
  class RunnerHandler
    # Marshals the method and arguments and sends them to script/runner.
    def self.handle(object, method, args, options = {})
      fork do
        system(%{script/runner "BackgroundLite::RunnerHandler.execute '#{encode(object)}', '#{method}', '#{encode(args)}'"})
      end
    end
    
    # Executes an encoded message which was sent via command line to runner
    def self.execute(object, method, args)
      object, args = self.decode(object), self.decode(args)
      puts "--- executing method: #{method}\n--- with variables: #{args.inspect}\n--- in object: #{object.inspect}"
      
      object.send(method, *args)
      puts "--- it happened!"
    end
  
  protected
    def self.encode(obj)
      Base64.encode64(Marshal.dump(obj))
    end
  
    def self.decode(string)
      message = Base64.decode64(string)
      begin
        obj = Marshal.load(message)
      rescue ArgumentError => e
        # Marshal.load does not trigger const_missing, so we have to do this
        # ourselves.
        e.message.split(' ').last.constantize
        retry
      end
      obj
    end
  end
end

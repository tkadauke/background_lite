module BackgroundLite
  # This background handler runs the given method in a forked child process.
  class ForkHandler
    # Runs the method in a forked child process
    def self.handle(object, method, args, options = {})
      fork do
        object.send(method, *args)
      end
    end
  end
end

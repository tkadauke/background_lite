module BackgroundLite
  # Executes the method in-process. This handler is probably most useful as a
  # fallback handler.
  class InProcessHandler
    # Executes the method in-process.
    def self.handle(object, method, args, options = {})
      object.send(method, *args)
    end
  end
end

module BackgroundLite
  # Forgets the background task. This handler is probably most useful as a
  # fallback handler.
  class ForgetHandler
    # Does nothing
    def self.handle(object, method, args, options = {})
      # do nothing
    end
  end
end

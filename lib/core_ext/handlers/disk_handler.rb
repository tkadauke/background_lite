module BackgroundLite
  # Stores the serialized message on disk. This handler is probably most useful
  # as a fallback handler.
  class DiskHandler
    # The directory in which the serialized messages should be stored.
    @@dirname = nil
    cattr_accessor :dirname
    
    # Marshals the message and the locals into a file in the folder specified by
    # dirname.
    def self.handle(object, method, args, options = {})
      filename = "background_#{Time.now.to_f.to_s}"
      File.open("#{dirname}/#{filename}", 'w') do |file|
        file.print(Marshal.dump([object, method, args]))
      end
    end
    
    # Replays all marshalled background tasks in the order in which they were
    # stored into the folder specified by dirname.
    def self.recover(handler)
      handler_class = "BackgroundLite::#{handler.to_s.camelize}Handler".constantize
      Dir.entries(dirname).grep(/^background/).sort.each do |filename|
        path = "#{dirname}/#{filename}"
        File.open(path, 'r') do |file|
          object, method, args = Marshal.load(file)
          handler_class.handle(object, method, args)
        end
        FileUtils.rm(path)
      end
    end
  end
end

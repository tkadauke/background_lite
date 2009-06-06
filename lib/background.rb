# This module holds methods for background handling
module BackgroundLite
  # This class is for configuring defaults of the background processing
  # framework(s) you use. You can configure the frameworks either using the
  # accessors in this class, or by listing them in the config/background.yml
  # configuration file. See Class#background_method for details.
  class Config
    # Contains the default background handler that is chosen, if none is
    # specified in the call to Kernel#background.
    @@default_handler = [:in_process, :forget]
    cattr_accessor :default_handler
    
    # Contains the default error reporter.
    @@default_error_reporter = :stdout
    cattr_accessor :default_error_reporter
    
    def self.config #:nodoc:
      @config ||= YAML.load(File.read("#{RAILS_ROOT}/config/background.yml")) rescue { RAILS_ENV => {} }
    end
    
    def self.default_config #:nodoc:
      @default_config ||= (config['default'] || {})
    end
    
    def self.load(configuration) #:nodoc:
      if configuration.blank?
        default_config
      else
        loaded_config = ((config[RAILS_ENV] || {})[configuration] || {})
        default_config.merge(loaded_config.symbolize_keys || {})
      end
    end
  end
  
  # holds whether or not background handling is disabled.
  mattr_accessor :disabled
  self.disabled = false
  
  # Disables background handling.
  def self.disable!
    BackgroundLite.disabled = true
  end
  
  # Enables background handling.
  def self.enable!
    BackgroundLite.disabled = false
  end
  
  # Disables background handling for the given block.
  def self.disable(&block)
    value = BackgroundLite.disabled
    begin
      BackgroundLite.disable!
      yield
    ensure
      BackgroundLite.disabled = value
    end
  end
  
  # Sends a message to the background. The message contains an object, a method,
  # and the methods arguments. The object and the arguments will be cloned for
  # background handling.
  #
  # The options hash lets you choose the background handler(s) and their
  # configuration, if available.
  #
  # You should rarely need to use this method directly. Rather use
  # Class#background_method to mark a method to be executed in the background.
  def self.send_to_background(object, method, args = [], options = {})
    object = object.clone_for_background
    args = args.collect { |a| a.clone_for_background }
    
    config = (BackgroundLite::Config.load(options[:config].to_s) || {})
    handler = if BackgroundLite.disabled
      [:in_process]
    else
      [options.delete(:handler) || config[:handler] || BackgroundLite::Config.default_handler].flatten
    end
    reporter = options.delete(:reporter) || config[:reporter] || BackgroundLite::Config.default_error_reporter
    
    handler.each do |hand|
      options = {}
      if hand.is_a? Hash
        raise "Malformed handler options Hash" if hand.keys.size != 1
        options = hand.values.first
        hand = hand.keys.first
      end
      
      begin
        BackgroundLite.disable do
          "BackgroundLite::#{hand.to_s.camelize}Handler".constantize.handle(object, method, args, options)
        end
        
        return hand
      rescue Exception => e
        "BackgroundLite::#{reporter.to_s.camelize}ErrorReporter".constantize.report(e)
      end
    end
  end
end

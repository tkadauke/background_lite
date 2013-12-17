require 'digest/sha1'
require 'logger' 
require 'benchmark'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/module/attribute_accessors'

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
    
    # Logger for debugging purposes.
    cattr_writer :default_logger
    
    # Time in seconds a job may take before it is logged into slow log.
    # Set to 0 for no logging.
    @@slow_threshold = 0
    cattr_accessor :slow_threshold
    
    def self.config #:nodoc:
      @config ||= YAML.load(File.read("#{Rails.root}/config/background.yml")) rescue { Rails.env => {} }
    end
    
    def self.default_config #:nodoc:
      @default_config ||= begin
        if config[Rails.env]
          (config[Rails.env]['default'] || config['default'] || {})
        else
          (config['default'] || {})
        end
      end
    end

    def self.default_logger #:nodoc:
      fallback_logger = if Object.const_defined?("Rails")
        Rails.logger
      else
        logger = Logger.new(STDOUT)
        logger.level = Logger::WARN
        logger
      end
      @@default_logger ||= config['logger'] || fallback_logger
    end
    
    def self.load(configuration) #:nodoc:
      if configuration.blank?
        default_config
      else
        loaded_config = ((config[Rails.env] || {})[configuration] || {})
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
    logger = options.delete(:logger) || config[:logger] || BackgroundLite::Config.default_logger
    
    handler.each do |hand|
      if hand.is_a? Hash
        raise "Malformed handler options Hash" if hand.keys.size != 1
        options = hand.values.first
        hand = hand.keys.first
      end
      options ||= {}
      
      begin
        BackgroundLite.disable do
          if logger.debug?
            # Transaction ID is currently only used for debugging to find corresponding
            # messages on both sides of the queue. It is optional and should be expected 
            # to be nil
            options[:transaction_id] = Digest::SHA1.hexdigest(object.to_s + method.to_s + args.inspect + Time.now.to_s)
            logger.debug("Sending to background: Object: #{object.inspect} Method: #{method} Args: #{args.inspect} Options: #{options.inspect}")      
          end
          
          time = Benchmark.realtime do
            "BackgroundLite::#{hand.to_s.camelize}Handler".constantize.handle(object, method, args, options)
          end

          if BackgroundLite::Config.slow_threshold > 0 && time > BackgroundLite::Config.slow_threshold
            logger.fatal("Slow background job (#{time}s): #{object.class.name}##{method}(#{args.inspect}) on object #{object.inspect}")
          end
        end
        
        return hand
      rescue Exception => e
        "BackgroundLite::#{reporter.to_s.camelize}ErrorReporter".constantize.report(e)
      end
    end
    return nil
  end
end

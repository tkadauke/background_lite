module BackgroundLite #:nodoc:
  # This class is for configuring defaults of the background framework.
  class Config
    # Contains the default background handler that is chosen, if none is specified in the call to Kernel#background.
    @@default_handler = [:in_process, :forget]
    cattr_accessor :default_handler
    
    # Contains the default error reporter.
    @@default_error_reporter = :stdout
    cattr_accessor :default_error_reporter
    
    def self.config
      @config ||= YAML.load(File.read("#{RAILS_ROOT}/config/background.yml")) rescue { RAILS_ENV => {} }
    end
    
    def self.default_config
      @default_config ||= (config['default'] || {})
    end
    
    def self.load(configuration)
      if configuration.blank?
        default_config
      else
        loaded_config = ((config[RAILS_ENV] || {})[configuration] || {})
        default_config.merge(loaded_config.symbolize_keys || {})
      end
    end
  end
  
  mattr_accessor :disabled
  self.disabled = false
  
  def self.disable!
    BackgroundLite.disabled = true
  end
  
  def self.enable!
    BackgroundLite.disabled = false
  end
  
  def self.disable(&block)
    value = BackgroundLite.disabled
    begin
      BackgroundLite.disable!
      yield
    ensure
      BackgroundLite.disabled = value
    end
  end
  
  def self.send_to_background(object, method, args, options)
    args = args.collect { |a| a.clone_for_background rescue a }
    
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

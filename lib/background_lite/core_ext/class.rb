class Class
  def clone_for_background
    self
  end

  # Decorates a method to be executed in the background.
  #
  # To decorate a class' method, background_method must be called from inside a
  # class and the first argument must be a symbol, containing the name of the
  # method to decorate.
  #
  #    class FactorialClass
  #      def factorial(number)
  #        result = (1..number).inject(1) { |num, res| res * num }
  #        Logger.log("The result is #{result}")
  #      end
  #
  #      # execute all calls to FactorialClass#factorial in the background
  #      background_method :factorial
  #    end
  #
  # === Choosing a handler
  #
  # There are several ways to execute a task in the background. To choose your
  # particular handler and optionally some fallback handlers, in case the
  # background process doesn't respond, use the :handler option.
  #
  #    background_method :handler => [:active_messaging, :disk]
  #
  # To configure a handler, use a Hash instead of a Symbol like this:
  #
  #    background_method :handler => [{ :active_messaging => { :queue => :my_queue } }, :disk]
  #
  # === Options
  #
  # handler:: The background handler to use.
  #           If none is specified, the BackgroundLite::Config.default_handler
  #           is used. Available handlers are :active_messaging, :in_process,
  #           :forget, :disk, and :test. This option can also be an array, in
  #           which case all of the handlers are tried in order, until one
  #           succeeds. Each element of the array may be a Symbol or a hash with
  #           one element. If it is a hash, the key is the handler name, and the
  #           value contains configuration options for the handler.
  #
  # reporter:: A reporter class that reports errors to the user. Available
  #            reporters are :stdout, :silent, :exception_notification, and
  #            :test.
  #
  # === Background Configurations
  #
  # Instead of specifying the :handler: and :reporter: params directly, you can
  # also specify a configuration for your particular background call, which is
  # configured in RAILS_ROOT/config/background.yml. This file has the following
  # format:
  #
  #    test:
  #      queue:
  #        :handler: test
  #        :reporter: silent
  #    production
  #      queue:
  #        :handler:
  #        - :active_messaging:
  #            :queue: background
  #        :reporter: exception_notification
  #
  # You can also specify a default configuration like this:
  #
  #    default:
  #      :handler:
  #      - :in_process:
  #      - :disk:
  #
  # === Precedence
  #
  # For the handler and reporter options, the precedence is as follows, from
  # high to low:
  #
  # - method argument
  # - background.yml configuration, if supplied
  # - background.yml default configuration
  # - BackgroundLite::Config.default_handler / BackgroundLite::Config.default_error_reporter
  #
  # === Writing own handlers
  #
  # Writing handlers is easy. A background handler class must implement a
  # self.handle method that accepts a hash containing local variables as well as
  # an options hash for the block to execute. An error reporter must implement a
  # self.report method that accepts an exception object. Note that for most
  # non-fallback handlers you need to write a background task that accepts and
  # executes the block. See BackgroundLite::ActiveMessagingHandler for an
  # example on how to do that.
  #
  # === Things to note
  #
  # * Since it is not possible to serialize singleton objects, all objects are
  #   dup'ed before serialization. This means that all singleton methods get
  #   stripped away on serialization.
  # * Every class used in a background method must be available in the
  #   background process as well.
  # * Subject to the singleton restriction mentioned above, the self object is
  #   correctly and automatically serialized and can be referenced in the
  #   background method using the self keyword.
  def background_method(method, options = {})
    alias_method_chain method, :background do |aliased_target, punctuation|
      self.class_eval do
        define_method "#{aliased_target}_with_background#{punctuation}" do |*args|
          BackgroundLite.send_to_background(self, "#{aliased_target}_without_background#{punctuation}", args, options)
        end
      end
    end
  end
end

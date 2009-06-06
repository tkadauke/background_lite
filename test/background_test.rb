require File.expand_path(File.dirname(__FILE__) + '/abstract_unit')


class BackgroundLiteTest < Test::Unit::TestCase # :nodoc:
  def define_background_class
    Object.send :remove_const, :SomeBackgroundClass if Object.const_defined?(:SomeBackgroundClass)
    Object.const_set(:SomeBackgroundClass, Class.new)
    
    SomeBackgroundClass.class_eval do
      def add_three(a, b, c)
        a + b + c
      end

      def puts_something
        puts "something"
      end
    end
  end
  
  def setup
    define_background_class
    BackgroundLite::Config.default_handler = [:test, :forget]
    BackgroundLite::Config.default_error_reporter = :test
  end
  
  def teardown
    BackgroundLite::TestHandler.reset
    BackgroundLite::TestErrorReporter.last_error = nil
    BackgroundLite.enable!
  end
  
  def test_should_decorate_method_without_parameters
    SomeBackgroundClass.background_method :puts_something
    obj = SomeBackgroundClass.new
    assert obj.respond_to?(:puts_something_with_background)
    assert obj.respond_to?(:puts_something_without_background)
  end

  def test_should_decorate_method_with_parameters
    SomeBackgroundClass.background_method :add_three
    obj = SomeBackgroundClass.new
    assert obj.respond_to?(:add_three_with_background)
    assert obj.respond_to?(:add_three_without_background)
    assert_equal 6, obj.add_three_without_background(1, 2, 3)
    assert_not_equal 6, obj.add_three_with_background(1, 2, 3)
  end
  
  def test_should_run_code_block_in_background
    SomeBackgroundClass.background_method :add_three
    obj = SomeBackgroundClass.new
    obj.add_three(1, 2, 3)
    assert_equal 'add_three_without_background', BackgroundLite::TestHandler.method
    assert BackgroundLite::TestHandler.executed
  end
  
  def test_should_store_locals
    SomeBackgroundClass.background_method :add_three
    obj = SomeBackgroundClass.new
    obj.add_three(1, 2, 3)
    assert_equal [1, 2, 3], BackgroundLite::TestHandler.args
  end
  
  def test_should_work_with_unduppable_locals
    SomeBackgroundClass.background_method :add_three
    obj = SomeBackgroundClass.new
    
    a = 10
    b = :symbol
    c = nil
    
    obj.add_three(a, b, c)
    assert_equal 10, BackgroundLite::TestHandler.args[0]
    assert_equal :symbol, BackgroundLite::TestHandler.args[1]
    assert_equal nil, BackgroundLite::TestHandler.args[2]
  end
  
  def test_should_use_correct_self_object
    SomeBackgroundClass.background_method :add_three
    obj = SomeBackgroundClass.new
    obj.add_three(1, 2, 3)
    assert_not_equal obj, BackgroundLite::TestHandler.object
  end
  
  def test_should_use_specified_handler_and_fallback
    BackgroundLite::InProcessHandler.expects(:handle).raises(RuntimeError, 'lala')
    SomeBackgroundClass.background_method :puts_something, :handler => [:in_process, :test]
    obj = SomeBackgroundClass.new
    obj.puts_something
    assert_equal "lala", BackgroundLite::TestErrorReporter.last_error.message
    # check if test handler was executed
    assert BackgroundLite::TestHandler.executed
  end
  
  def test_should_use_options_hash_for_handler
    SomeBackgroundClass.background_method :add_three, :handler => [{:test => { :some_option => 2 }}]
    obj = SomeBackgroundClass.new
    obj.add_three(1, 2, 3)
    assert_not_nil BackgroundLite::TestHandler.options
    assert_equal 2, BackgroundLite::TestHandler.options[:some_option]
  end
  
  def test_should_correctly_marshal_classes
    assert_equal SomeBackgroundClass, Marshal.load(Marshal.dump(SomeBackgroundClass.clone_for_background))
  end
  
  def test_should_correctly_marshal_singleton_objects
    obj = Object.new
    def obj.some_method
    end
    
    assert Marshal.load(Marshal.dump(obj.clone_for_background))
  end
  
  def test_should_disable_background
    BackgroundLite.enable!
    BackgroundLite.disable do
      assert BackgroundLite.disabled
    end
    assert !BackgroundLite.disabled
  end

  def test_should_disable_background_if_already_disabled
    BackgroundLite.disable!
    BackgroundLite.disable do
      assert BackgroundLite.disabled
    end
    assert BackgroundLite.disabled
  end
  
  def test_should_reenable_background_when_exception_is_raised_in_block
    begin
      BackgroundLite.disable do
        raise 'grr'
      end
    rescue RuntimeError => e
      assert_equal 'grr', e.message
    end
    
    assert !BackgroundLite.disabled
  end
end

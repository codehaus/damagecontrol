require 'test/unit/assertions'

module MockIt
  class Mock
    include Test::Unit::Assertions
    
    def initialize
      @expected_methods=[]
      @expected_validation_procs=[]
      @expect_not_called=[]
      @setup_call_procs={}
    end
    
    # What's this method needed for? (AH)
    def __expect_not_called(method)
      @expect_not_called<<method
    end
    
    def __expect(method, &validation_proc)
      validation_proc=Proc.new {|*args| nil} if validation_proc.nil?
      @expected_methods<<method
      @expected_validation_procs<<validation_proc
    end
    
    def __setup(method, &proc)
      proc=Proc.new {|*args| nil} if proc.nil?
      @setup_call_procs[method]=proc
    end
    
    def __verify
      assert_all_expected_methods_called
    end
    
    def method_missing(method, *args, &proc)
      if(is_expected_not_to_be_called(method)) then
        flunk("#{method} expected to never be called")
      elsif(is_setup_call(method)) then
        handle_setup_call(method, *args, &proc)
      else
        handle_expected_call(method, *args, &proc)
      end
    end
    
    def respond_to?(method)
      return super.respond_to?(method) if super.respond_to?(method)
      method = symbol(method)
      return true if is_setup_call(method)
      return true if currently_expected_method == method
      false
    end
    
    private
    
    def symbol(string)
      return nil if string==""
      if string.is_a? String then string.intern else string end
    end
    
    def assert_all_expected_methods_called
      assert(@expected_validation_procs.empty?, "not all expected methods called, calls left: #{@expected_methods.inspect}")
    end
    
    def is_expected_not_to_be_called(method)
      @expect_not_called.index(method)
    end
    
    def is_setup_call(method)
      not @setup_call_procs[method].nil?
    end
    
    def handle_setup_call(method, *args, &proc)
      @setup_call_procs[method].call(*args, &proc)
    end
    
    def handle_expected_call(method, *args, &proc)
      assert_equal(currently_expected_method, method, "got unexpected call")
      validation_proc = current_validation_proc
      next_call
      validation_proc.call(*args, &proc)
    end
    
    def currently_expected_method
      if @expected_methods.empty? then nil 
      else @expected_methods[0] end
    end
    
    def current_validation_proc
      if @expected_validation_procs.empty? then nil 
      else @expected_validation_procs[0] end
    end
    
    def next_call
      @expected_methods.delete_at(0)
      @expected_validation_procs.delete_at(0)
    end
    
  end
end


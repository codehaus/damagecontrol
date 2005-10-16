class FibonacciExample < Spec::Context
  def should_work_upto_2
    fib = Fibonacci.new
    
    fib.value(0).should_equal 0
    fib.value(1).should_equal 0
    fib.value(2).should_equal 1
  end
end
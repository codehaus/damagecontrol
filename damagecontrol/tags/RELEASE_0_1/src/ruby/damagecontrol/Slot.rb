module DamageControl

=begin
  A simple a simple one-valued thread hand-over pattern
  Author: Jon Tirsen
=end
  class Slot
    def initialize
      clear
    end
    
    def clear
      # TODO possible threading problem here!!
      # this order is important
      # first block the other threads by creating a new closed latch, then clear the actual value
      @value_set_latch = Latch.new
      @value =  nil
    end
  
    def get
      @value_set_latch.wait
      @value
    end
    
    def set(value)
      # TODO possible threading problem here!!
      @value = value
      @value_set_latch.release
    end
    
    def will_block_on_get?
      @value_set_latch.closed?
    end
    
    def empty?
      @value.nil?
    end
  end
    
  class BlockingGet < Exception
  end

=begin
  Use during single-threaded unit tests.
  Author: Jon Tirsen
=end
  class FailOnBlockSlot < Slot
    def get
      raise BlockingGet.new if will_block_on_get?
      super.get
    end
  end

end
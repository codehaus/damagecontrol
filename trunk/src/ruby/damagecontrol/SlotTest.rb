require 'damagecontrol/Slot'

module DamageControl

  class SlotTest < Test::Unit::TestCase
    def test_get_returns_previously_set_value
      slot = Slot.new
      value = Object.new
      slot.set(value)
      assert_same(value, slot.get)
    end
    
    def test_initially_blocks_and_has_empty_value
      slot = Slot.new
      assert(slot.will_block_on_get?)
      assert(slot.empty?)
    end
    
    def test_clear_makes_it_empty_and_blocking
      slot = Slot.new
      assert(slot.will_block_on_get?)
      assert(slot.empty?)
    end
  end
  
  class FailOnBlockSlotTest < Test::Unit::TestCase
    def test_fails_on_blocking_get
      assert_raises(BlockingGet) { FailOnBlockSlot.new.get }
    end
  end

end

require 'test/unit'
require 'damagecontrol/AsyncComponent'
require 'damagecontrol/HubTestHelper'

module DamageControl

  class SucceedingAsyncComponent < AsyncComponent
    attr_reader :processed_messages
    
    def initialize(hub)
      super(hub)
      @processed_messages = []
    end
    
    def process_message(message)
      processed_messages<<message
    end
  end
  
  class FailingAsyncComponent < SucceedingAsyncComponent
    def process_message(message)
      super(message)
      raise "error"
    end
  end

  class AsyncComponentTest < Test::Unit::TestCase

    include HubTestHelper
    
    def setup
      fail
      create_hub
      @messages = [1, 2, 3]
    end

    def test_enqueued_message_processed_on_tick
      comp = SucceedingAsyncComponent.new(hub)
      @messages.each {|message|
        hub.publish_message(message)
      }
      comp.force_tick
      assert_equal(@messages, comp.processed_messages)
    end
    
    def test_error_on_process_message_will_process_message_again_on_next_tick
      comp = FailingAsyncComponent.new(hub)
      @messages.each {|message|
        hub.publish_message(message)
      }
      comp.force_tick
      assert_equal(@messages, comp.processed_messages)
      @messages.each {|message|
        assert(!comp.consumed_message?(message))
      }
      comp.force_tick
      assert_equal(@messages + @messages, comp.processed_messages)
    end
    

    def test_consumed_message_not_processed_on_next_tick
      comp = SucceedingAsyncComponent.new(hub)
      @messages.each {|message|
        hub.publish_message(message)
      }
      comp.force_tick
      assert_equal(@messages, comp.processed_messages)
      @messages.each {|message|
        assert(comp.consumed_message?(message))
      }
    end

  end
end
require 'damagecontrol/core/Hub'

module DamageControl

  module HubTestHelper
  
    attr_reader :hub
    attr_reader :messages_from_hub

    def create_hub
      @hub = Hub.new
      @hub.add_subscriber(self)
      @messages_from_hub = []
      @hub
    end
    
    def messages_from_hub
      @messages_from_hub
    end
        
    def receive_message(message)
      messages_from_hub<<message
    end
    
    def message_types
      messages_from_hub.collect{|message| message.class}
    end
    
    def assert_message_types_from_hub(expected)
      assert_equal(expected, message_types)
    end

    def assert_no_messages
      assert(messages_from_hub.empty?)
    end

    def assert_got_message(clazz)
      message_types.index(clazz)
    end
    
  end
  
end
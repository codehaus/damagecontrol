require 'pebbles/Space'

# This is now just a temporary adapter for Pebbles::MulticastSpace
# This class should be removed
module DamageControl

  class Hub < Pebbles::MulticastSpace
    def add_subscriber(consumer)
      add_consumer(consumer)
    end
    
    def publish_message(message)
      puts "publishing #{message}"
      put(message)
    end
  end
  
end
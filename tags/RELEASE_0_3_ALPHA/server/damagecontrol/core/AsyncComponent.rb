require 'pebbles/Space'

# This is now just a temporary adapter for Pebbles::Space
# This class should be removed and the others refactored to use on_message
module DamageControl
  class AsyncComponent < Pebbles::Space
    attr_reader :channel
    
    def initialize(multicast_space)
      super
      @channel = multicast_space
      @channel.add_consumer(self) unless channel.nil?
    end

    def on_message(o)
      process_message(o)
    end

  end
end

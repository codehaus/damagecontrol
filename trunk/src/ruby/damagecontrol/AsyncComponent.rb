require 'damagecontrol/Timer'

module DamageControl
  # TODO make it an adapter (as well as a superclass) for other components
  class AsyncComponent
    attr_reader :channel
    
    include TimerMixin
    
    def initialize(channel)
      super()
      @inq = []
      @channel = channel
      channel.add_subscriber(self) unless channel.nil?
    end

    def tick(time)
      schedule_next_tick
      process_messages
    end
    
    def process_messages
      # process copy of array so that process_message can remove entries via consume
      @inq.clone.each do |message|
        protect do
          process_message(message)
          consume_message(message)
        end
      end
    end

    def consume_message(message)
      @inq.delete(message)
    end
    
    def enq_message(message)
      @inq.push(message)
    end
  
    def receive_message(message)
      enq_message(message)
    end
    
    def consumed_message?(message)
      !@inq.index(message)
    end
  end
end

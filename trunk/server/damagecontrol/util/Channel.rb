require 'damagecontrol/util/Timer'

module DamageControl

  class Channel
    attr_reader :last_message
    
    include Threading
    
    def initialize
      @clock = Clock.new
      @subscribers = []
    end   
        
    def publish_message(message)
      protect do
        @last_message=message
        @subscribers.each do |subscriber|
          subscriber.receive_message(message)
        end
      end
    end
    
    def add_subscriber(subscriber)
      @subscribers << subscriber
    end
  end

end
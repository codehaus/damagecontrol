require 'damagecontrol/Clock'

module DamageControl

  class Hub
    attr_reader :last_message
    attr_accessor :clock
    
    def initialize
      @clock = Clock.new
      @subscribers = Array.new
    end   
        
    def publish_message(message)
      @last_message=message
      @subscribers.each {|subscriber|
        subscriber.receive_message(message)
      }
    end
    
    def add_subscriber(subscriber)
      @subscribers << subscriber
    end
  end

end
module DamageControl

  class Channel
    attr_reader :last_message
    
    def initialize
      @clock = Clock.new
      @subscribers = []
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
require 'test/unit'

require 'damagecontrol/Timer'

module DamageControl

  class BuildDelayer
    attr_accessor :quiet_period
    
    include TimerMixin
  
    def initialize(receiver)
      @receiver = receiver
      @quiet_period = quiet_period
    end
    
    def receive_message(message)
      @last_message = message
      @last_message_time = @clock.current_time
    end
    
    def tick(time)
      if nil|@last_message && time > @last_message_time + quiet_period
        @receiver.receive_message( @last_message )
      end
      schedule_next_tick
    end
  end
end
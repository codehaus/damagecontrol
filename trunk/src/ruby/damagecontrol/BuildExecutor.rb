require 'damagecontrol/BuildEvents'
require 'damagecontrol/scm/DefaultSCMRegistry'

module DamageControl
  
  # This class tells the build to execute and reports
  # progress as events back to the channel
  #
  class BuildExecutor       
    def initialize(channel)
      @channel = channel
      @channel.add_subscriber(self)
    end
    
    def receive_message(message)
      if message.is_a? BuildRequestEvent
        message.build.checkout { |progress|
          @channel.publish_message(BuildProgressEvent.new(message.build, progress))
        }
        message.build.execute { |progress|
          @channel.publish_message(BuildProgressEvent.new(message.build, progress))
        }
        @channel.publish_message(BuildCompleteEvent.new(message.build))
      end
    end
  end  
end

require 'damagecontrol/BuildEvents'
require 'damagecontrol/scm/DefaultSCMRegistry'

module DamageControl
  
  # This class tells the build to execute and reports
  # progress as events back to the hub
  #
  class BuildExecutor       
    def initialize(hub)
      @hub = hub
      @hub.add_subscriber(self)
    end
    
    def receive_message(message)
      if message.is_a? BuildRequestEvent
        message.build.checkout { |progress|
          @hub.publish_message(BuildProgressEvent.new(message.build, progress))
        }
        message.build.execute { |progress|
          @hub.publish_message(BuildProgressEvent.new(message.build, progress))
        }
        @hub.publish_message(BuildCompleteEvent.new(message.build))
      end
    end
  end  
end
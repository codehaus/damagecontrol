module DamageControl

  # Exits if the build is successful and the project
  # is damagecontrol. This is to ensure self-upgrading
  # which will happen if the server is started in an
  # infinite loop script as in damagecontrol/src/samples/codehaus
  class SelfUpgrader
    def initialize(channel)
      channel.add_subscriber(self)
    end
  
    def receive_message(message)
      if message.is_a? BuildCompleteEvent        
        if(message.build.successful && message.build.project_name == "damagecontrol")
          do_exit
        end
      end
    end
    
    def do_exit
      exit
    end
  end
    
end

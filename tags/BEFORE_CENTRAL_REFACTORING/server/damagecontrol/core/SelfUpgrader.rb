require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildEvents'

module DamageControl

  # Exits if the build is successful and the project
  # is damagecontrol. This is to ensure self-upgrading
  # which will happen if the server is started in an
  # infinite loop script as in damagecontrol/src/samples/codehaus
  class SelfUpgrader < AsyncComponent
    def process_message(message)
      if message.is_a? BuildCompleteEvent
        if((Build::SUCCESSFUL == message.build.status) && message.build.project_name == "damagecontrol")
          do_exit
        end
      end
    end
    
    def do_exit
      channel.publish_message(UserMessage.new("DamageControl is restarting (self upgrade)"))
      # let the publishers get a chance to publish before we die
      sleep(5)
      exit!
    end
  end
    
end

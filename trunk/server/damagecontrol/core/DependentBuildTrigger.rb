require 'damagecontrol/core/BuildEvents'

module DamageControl
  class DependentBuildTrigger
    def initialize(channel)
      @channel = channel
      @channel.add_consumer(self)
    end

    def put(message)
      if (message.is_a? BuildCompleteEvent)
        dependents = message.build.config["dependent_projects"]
        return unless dependents
        dependents.each do |project_name|
          @channel.put(DoCheckoutEvent.new(project_name, true)) if message.build.status == Build::SUCCESSFUL
        end
      end
    end
  end
end

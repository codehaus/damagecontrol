require 'damagecontrol/core/BuildEvents'

module DamageControl
  class DependentBuildTrigger
    def initialize(hub, project_config_repository)
      @hub = hub
      @hub.add_subscriber(self)
      @project_config_repository = project_config_repository
    end

    def put(message)
      if (message.is_a? BuildCompleteEvent)
        dependents = message.build.config["dependent_projects"]
        return unless dependents
        dependents.each do |project_name|
          @hub.publish_message(BuildRequestEvent.new(@project_config_repository.create_build(project_name, message.build.timestamp))) if 
            message.build.status == Build::SUCCESSFUL
        end
      end
    end
  end
end

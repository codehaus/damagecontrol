require 'damagecontrol/core/AsyncComponent'

module DamageControl
  class BuildPoller < AsyncComponent
    def initialize(channel, project_configuration_repository)
      super(channel)
      @project_configuration_repository = project_configuration_repository
      @project_ticks = Hash.new(0)
    end
    
    def tick(time)
      @project_configuration_repository.project_names.each do |project_name|
        project_config = @project_configuration_repository.project_config(project_name)
        poll_interval = project_config["poll_interval"]
        if(poll_interval)
          ticks = @project_ticks[project_name] +1
          @project_ticks[project_name] = ticks
          if(ticks == poll_interval)
            build = @project_configuration_repository.create_build(project_name, Time.new.utc)
            build.status = Build::QUEUED
            channel.publish_message(BuildRequestEvent.new(build))
          end
        end
      end
    end
  end
end

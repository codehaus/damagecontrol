require 'damagecontrol/core/BuildEvents'

module DamageControl
  class BuildNumberIncreaser
    def initialize(hub, project_config_repository)
      hub.add_consumer(self)
      @project_config_repository = project_config_repository
    end
    
    def put(evt)
      if (evt.is_a?(BuildCompleteEvent))
        @project_config_repository.next_build_number(evt.build.project_name) if evt.build.successful?
      end
    end
  end
end
require 'damagecontrol/core/BuildEvents'

class BuildNumberIncreaser
  def initialize(hub, project_config_repository)
    hub.add_subscriber(self)
    @project_config_repository = project_config_repository
  end
  
  def receive_message(evt)
    if (evt.is_a?(BuildCompleteEvent))
      @project_config_repository.next_build_number(evt.build.project_name) if evt.build.successful?
    end
  end
end
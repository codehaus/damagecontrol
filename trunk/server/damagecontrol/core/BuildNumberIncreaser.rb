require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/Logging'

module DamageControl
  class BuildNumberIncreaser
		include Logging
	
    def initialize(hub, project_config_repository)
      hub.add_consumer(self)
      @project_config_repository = project_config_repository
    end
    
    def put(evt)
      if (evt.is_a?(BuildStartedEvent))
				logger.info("got build started event: #{evt}")
        @project_config_repository.next_build_number(evt.build.project_name)
      end
    end
  end
end
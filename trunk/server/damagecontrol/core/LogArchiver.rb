require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/FileUtils'

module DamageControl
  class LogArchiver
    include FileUtils
    
    def initialize(hub, project_config_repository)
      hub.add_subscriber(self)
      @project_config_repository = project_config_repository
    end
    
    def receive_message(message)
      if(message.is_a?(BuildCompleteEvent))
        build = message.build
        
        archive_dir = @project_config_repository.archive_dir(build.project_name, build.timestamp_as_s)
        
        logs_to_archive = build.config["logs_to_archive"]
        if(logs_to_archive)
          logs_to_archive.each do |pattern|
            Dir["#{build.scm.working_dir}/#{pattern}"].each do |file|
              mkdir_p(archive_dir)
              cp(file, archive_dir)
            end
          end
        end
      end
    end
  end
end
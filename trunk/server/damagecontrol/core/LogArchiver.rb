require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/util/Logging'

module DamageControl
  class LogArchiver
    include FileUtils
    include Logging
    
    def initialize(hub)
      hub.add_subscriber(self)
    end
    
    def receive_message(message)
      if(message.is_a?(BuildCompleteEvent))      
        build = message.build
        
        archive_dir = build.archive_dir
        
        logs_to_archive = build.config["logs_to_archive"]
        if(logs_to_archive)
          logger.info("archiving log files #{logs_to_archive} for #{build.project_name} into directory #{archive_dir}")
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
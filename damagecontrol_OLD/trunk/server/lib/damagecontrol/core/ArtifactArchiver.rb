require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/util/Logging'

module DamageControl
  class ArtifactArchiver
    include FileUtils
    include Logging
    
    def initialize(hub, project_directories)
      hub.add_consumer(self)
      @project_directories = project_directories
    end
    
    def put(message)
      if(message.is_a?(BuildCompleteEvent))      
        build = message.build
        checkout_dir = @project_directories.checkout_dir(build.project_name)

        archive_dir = @project_directories.archive_dir(build.project_name, build.dc_creation_time)
        
        artifacts_to_archive = build.config["artifacts_to_archive"]
        if(artifacts_to_archive)
          artifacts_to_archive.each do |pattern|
            file_pattern = "#{checkout_dir}/#{pattern}"
            Dir[file_pattern].each do |file|
              logger.info("archiving build artifact: #{file} for #{build.project_name} into directory #{archive_dir}")
              mkdir_p(archive_dir)
              cp_r(file, archive_dir)
            end
          end
        end
      end
    end
  end
end
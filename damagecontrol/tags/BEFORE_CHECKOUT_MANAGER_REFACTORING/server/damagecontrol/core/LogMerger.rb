require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/util/Logging'
require 'damagecontrol/util/XMLMerger'

module DamageControl
  class LogMerger
    include FileUtils
    include Logging
    
    def initialize(hub, project_directories)
      hub.add_subscriber(self)
      @project_directories = project_directories
    end
    
    def put(message)
      if(message.is_a?(BuildCompleteEvent))      
        build = message.build
        checkout_dir = @project_directories.checkout_dir(build.project_name)
        
        logs_to_merge = build.config["logs_to_merge"]
        if(logs_to_merge)
          mkdir_p(File.dirname(build.xml_log_file))
          XMLMerger.open("damagecontrol", File.open(build.xml_log_file, "w+")) do |merger|
            logger.info("merging log files #{logs_to_merge} for #{build.project_name} into #{build.xml_log_file}")
            logs_to_merge.each do |pattern|
              Dir["#{checkout_dir}/#{pattern}"].each do |file|
                File.open(file) do |xml_io|
                  merger.merge(xml_io)
                end
              end
            end
          end
        end
      end
    end
  end
end
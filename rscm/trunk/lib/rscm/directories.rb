require 'fileutils'
module RSCM

  # This class knows about locations of various files and directories.
  #
  module Directories
    include FileUtils

    def project_names
      result = Dir["#{basedir}/*/project.yaml"].collect do |f| 
        File.basename(File.dirname(f))
      end
      result.sort
    end
    module_function :project_names
    
    def checkout_dir(project_name)
      "#{project_dir(project_name)}/checkout"
    end
    module_function :checkout_dir

    def rss_file(project_name)
      "#{project_dir(project_name)}/rss.xml"
    end
    module_function :rss_file

    def trigger_checkout_dir(project_name)
      "#{project_dir(project_name)}/trigger_checkout"
    end
    module_function :trigger_checkout_dir

    def project_config_file(project_name)
      "#{project_dir(project_name)}/project.yaml"
    end
    module_function :project_config_file

    def project_dir(project_name)
      "#{basedir}/#{project_name}"
    end
    module_function :project_dir

    def basedir
      @@basedir ||= ENV["RSCM_BASE"] || File.expand_path(File.dirname(__FILE__) + "/../../target/work")
    end
    module_function :basedir

  end
  
end
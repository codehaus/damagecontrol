require 'damagecontrol/util/FileUtils'

module DamageControl

  class ProjectDirectories
    CONFIG_FILE_NAME = "conf.yaml"
      
    attr_reader :basedir
  
    def initialize(basedir)
      @basedir = basedir
    end
    
    def project_names
      result = Dir["#{basedir}/*/conf.yaml"].collect {|f| File.basename(File.dirname(f)) }
      result.sort
    end
    
    def project_dir(project_name)
      "#{basedir}/#{project_name}"
    end
    
    def checkout_dir(project_name)
      "#{project_dir(project_name)}/checkout"
    end
    
    def log_dir(project_name)
      FileUtils.mkdir_p("#{project_dir(project_name)}/log")
    end

    def report_dir(project_name)
      "#{project_dir(project_name)}/report"
    end

    def project_config_file(project_name)
      "#{project_dir(project_name)}/#{CONFIG_FILE_NAME}"
    end
    
    def log_timestamps(project_name)
      Dir["#{log_dir(project_name)}/*.log"].collect {|f| File.basename(f, ".log") }.sort
    end
    
    def log_file(project_name, timestamp)
      "#{log_dir(project_name)}/#{timestamp}.log"
    end
  end
  
end
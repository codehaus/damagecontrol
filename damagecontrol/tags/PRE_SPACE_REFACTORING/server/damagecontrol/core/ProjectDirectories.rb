require 'damagecontrol/util/FileUtils'

module DamageControl

  # I'd like to move away from this class eventually so please let's avoid having any direct references to this sucker
  # use ProjectConfigRepository instead (and delegate methods from there to here)
  # cheers --jon
  class ProjectDirectories
    CONFIG_FILE_NAME = "conf.yaml"
    HISTORY_FILE_NAME = "build_history.yaml"
      
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

    def build_history_file(project_name)
      "#{project_dir(project_name)}/#{HISTORY_FILE_NAME}"
    end    
    
    def log_timestamps(project_name)
      Dir["#{log_dir(project_name)}/*.log"].collect {|f| File.basename(f, ".log") }.sort
    end
    
    def log_file(project_name, timestamp)
      "#{log_dir(project_name)}/#{timestamp}.log"
    end
    
    def archive_dir(project_name, timestamp)
      "#{project_dir(project_name)}/archive/#{timestamp}"
    end

  end
  
end
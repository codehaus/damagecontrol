module DamageControl

  class ProjectDirectories
    CONFIG_FILE_NAME = "conf.yaml"
      
    attr_reader :basedir
  
    def initialize(basedir)
      @basedir = basedir
    end
    
    def project_dir(project_name)
      "#{basedir}/#{project_name}"
    end
    
    def checkout_dir(project_name)
      # append the name of the project to the end, hack that makes it a lot easier for poor cvs
      "#{project_dir(project_name)}/checkout/#{project_name}"
    end
    
    def log_dir(project_name)
      "#{project_dir(project_name)}/log"
    end

    def report_dir(project_name)
      "#{project_dir(project_name)}/report"
    end

    def project_config_file(project_name)
      "#{project_dir(project_name)}/#{CONFIG_FILE_NAME}"
    end    
  end
  
end
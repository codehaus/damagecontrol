require 'damagecontrol/web/Report'

module DamageControl
  class ErrorsReport < Report
    def id
      "errors"
    end
    
    def title
      "Standard Error"
    end
    
    def available?
      super && File.exists?(@project_directories.stderr_file(selected_build.project_name, selected_build.dc_creation_time))
    end
    
    def icon
      "smallicons/console_error.png"
    end
    
    def content
      "<iframe border=\"0\" width=\"100%\" height=\"100%\" src=\"../log/#{project_name}/build/#{selected_build.dc_creation_time.ymdHMS}/stderr.log\" />"
    end
  end
end
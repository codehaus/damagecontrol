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
      super && File.exists?(@build_history_repository.stderr_file(selected_build.project_name, selected_build.dc_creation_time))
    end
    
    def icon
      "smallicons/console_error.png"
    end
    
    def content
      "<pre class=\"console\">#{File.read(selected_build.error_log_file)}</pre>"
    end
  end
end
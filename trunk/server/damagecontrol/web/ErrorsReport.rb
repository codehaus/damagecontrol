require 'damagecontrol/web/Report'

module DamageControl
  class ErrorsReport < Report
    def id
      "errors"
    end
    
    def title
      "Errors"
    end
    
    def available?
      super && selected_build.log_file && File.exists?(selected_build.error_log_file)
    end
    
    def icon
      "icons/scroll_error.png"
    end
    
    def content
      "<pre class=\"console\">#{File.read(selected_build.error_log_file)}</pre>"
    end
  end
end
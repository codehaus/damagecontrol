require 'damagecontrol/web/Report'

module DamageControl
  class ConsoleOutputReport < Report
    def id
      "console"
    end
    
    def title
      "Console output"
    end
    
    def available?
      super && selected_build.log_file && File.exists?(selected_build.log_file)
    end
    
    def icon
      "icons/console_network.png"
    end
    
    def content
      "<pre class=\"console\">#{File.read(selected_build.log_file)}</pre>"
    end
  end
end
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
      "smallicons/console.png"
    end
    
    def content
      "<iframe border=\"0\" width=\"100%\" height=\"100%\" src=\"../log/#{project_name}?dc_creation_time=#{selected_build.dc_creation_time.ymdHMS}\" />"
    end
  end
end
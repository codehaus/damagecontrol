require 'damagecontrol/web/Report'

module DamageControl
  class ConsoleOutputReport < Report
    def id
      "console"
    end
    
    def title
      "Standard Out"
    end
    
    def available?
      super && File.exists?(@build_history_repository.stdout_file(selected_build.project_name, selected_build.dc_creation_time))
    end
    
    def icon
      "smallicons/console.png"
    end
    
    def content
      # TODO: just point the iframe straight to the file. Example:
      # http://builds.codehaus.org/damagecontrol/public/root/damagecontrol/build/20041129060728/stdout.log
      "<iframe border=\"0\" width=\"100%\" height=\"100%\" src=\"../log/#{project_name}?dc_creation_time=#{selected_build.dc_creation_time.ymdHMS}\" />"
    end
  end
end
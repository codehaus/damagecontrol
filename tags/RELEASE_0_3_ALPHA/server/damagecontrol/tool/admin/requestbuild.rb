require 'damagecontrol/tool/Task'
require 'damagecontrol/core/Build'

module DamageControl
class RequestBuildTask < XMLRPCClientTask
  commandline_option :projectname
  
  def run
    begin
      puts "Trigging build of #{projectname} DamageControl on #{url}"
      puts xmlrpc_client("build").trig(projectname, Build.format_timestamp(Time.now.utc))
      puts "OK Trigging build of #{projectname} DamageControl on #{url}"
    rescue Exception => e
      puts e.message
      puts e.backtrace.join("\n")
    end
  end
end
end

DamageControl::RequestBuildTask.new.run


require 'damagecontrol/tool/Task'
require 'damagecontrol/core/Build'

class RequestBuildTask < XMLRPCClientTask
  commandline_option :projectname
  
  def run
    xmlrpc_client("build").trig(projectname, Build.format_timestamp(Time.now.utc))
  end
end

RequestBuildTask.new.run

require 'damagecontrol/tool/Task'

class ShutdownServerTask < XMLRPCClientTask
  def run
    xmlrpc_client("control").shutdown
  end
end

ShutdownServerTask.new.run

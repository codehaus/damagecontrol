require 'damagecontrol/tool/Task'

module DamageControl
class ShutdownServerTask < XMLRPCClientTask
  def run
    xmlrpc_client("control").shutdown
  end
end
end

ShutdownServerTask.new.run

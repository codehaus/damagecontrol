$damagecontrol_home = File::expand_path('../..') 
$:<<"#{$damagecontrol_home}/src/ruby" 
 
require 'damagecontrol/Hub'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/BuildScheduler'
require 'damagecontrol/SocketTrigger'

include DamageControl 

def start_simple_server(buildsdir, port = 4711, allow_ips = [127.0.0.1])
  @hub = Hub.new
  @socket_trigger = SocketTrigger.new(@hub, port, allow_ips).start
  scheduler = BuildScheduler.new(@hub)
  scheduler.add_executor(BuildExecutor.new(@hub, buildsdir))
  scheduler.start
end

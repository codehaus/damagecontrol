$damagecontrol_home = File::expand_path('../..') 
$:<<"#{$damagecontrol_home}/src/ruby" 
 
require 'damagecontrol/Hub'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/BuildScheduler'
require 'damagecontrol/SocketTrigger'

include DamageControl 

def start_simple_server(buildsdir)
  @hub = Hub.new
  SocketTrigger.new(@hub).start
  scheduler = BuildScheduler.new(@hub)
  scheduler.add_executor(BuildExecutor.new(@hub, buildsdir))
  scheduler.start
end

$damagecontrol_home = File::expand_path('../..') 
$:<<"#{$damagecontrol_home}/src/ruby" 
 
require 'damagecontrol/Hub' 
require 'damagecontrol/SocketTrigger' 
require 'damagecontrol/BuildExecutor' 
require 'damagecontrol/LogWriter' 
require 'damagecontrol/SelfUpgrader' 
require 'damagecontrol/template/ShortTextTemplate' 
require 'damagecontrol/template/HTMLTemplate' 
require 'damagecontrol/publisher/IRCPublisher' 
require 'damagecontrol/publisher/FilePublisher' 
 
include DamageControl 
 
buildRoot = File.expand_path("/usr/local/builds") 
 
hub = Hub.new 
BuildExecutor.new(hub, "#{buildRoot}/builds").start 
LogWriter.new(hub, "#{buildRoot}/logs") 
FilePublisher.new(hub, "#{buildRoot}/reports", HTMLTemplate.new).start 
IRCPublisher.new(hub, "irc.codehaus.org", "\#damagecontrol", ShortTextTemplate.new).start 
SelfUpgrader.new(hub)
# Only accept connections from the same host or from hogshead.codehaus.org 
st = SocketTrigger.new(hub, 4713, ["127.0.0.1", "66.216.68.111"]).start 

# wait until ctrl-c 
st.join 
$:<<"../../src/ruby" 
$:<<"src/ruby" 

require 'simple' 
require 'damagecontrol/Hub' 
require 'damagecontrol/SocketTrigger' 
require 'damagecontrol/BuildExecutor' 
require 'damagecontrol/LogWriter' 
require 'damagecontrol/SelfUpgrader' 
require 'damagecontrol/template/ShortTextTemplate' 
require 'damagecontrol/template/HTMLTemplate' 
require 'damagecontrol/publisher/IRCPublisher' 
require 'damagecontrol/publisher/FilePublisher' 
require 'damagecontrol/publisher/EmailPublisher' 
require 'damagecontrol/publisher/JIRAPublisher'
require 'damagecontrol/Logging'

include DamageControl

Logging.quiet

start_simple_server(
  :BuildsDir => ARGV[0],
  :SocketTriggerPort => 4713, 
  :WebPort => 8081, 
  :AllowIPs => ["127.0.0.1" ])
irc_publisher = IRCPublisher.new(@hub, "irc.codehaus.org", "\#damagecontrol", ShortTextTemplate.new)
irc_publisher.handle = "dce2e"
irc_publisher.start

sleep 30

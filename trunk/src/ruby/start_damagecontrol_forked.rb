$:<<'../../lib'
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

Dir.chdir(ARGV[0])

start_simple_server(
  :SocketTriggerPort => 14711, 
  :HttpPort => 14712,
  :HttpsPort => 14713,
  :AllowIPs => ["127.0.0.1" ])
irc_publisher = IRCPublisher.new(@hub, "irc.codehaus.org", '#dce2e', ShortTextTemplate.new)
irc_publisher.handle = "server"
irc_publisher.start

sleep 60
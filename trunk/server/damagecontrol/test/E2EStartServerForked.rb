require 'damagecontrol/simple'
require 'damagecontrol/core/Hub' 
require 'damagecontrol/core/SocketTrigger' 
require 'damagecontrol/core/BuildExecutor' 
require 'damagecontrol/core/LogWriter' 
require 'damagecontrol/core/SelfUpgrader' 
require 'damagecontrol/template/ShortTextTemplate' 
require 'damagecontrol/template/HTMLTemplate' 
require 'damagecontrol/publisher/IRCPublisher' 
require 'damagecontrol/publisher/FilePublisher' 
require 'damagecontrol/publisher/EmailPublisher' 
require 'damagecontrol/publisher/JIRAPublisher'
require 'damagecontrol/util/Logging'

include DamageControl

Logging.quiet

basedir = ARGV[0]
timeout = ARGV[1].to_i
Dir.chdir(basedir)

start_simple_server(
  :SocketTriggerPort => 14711, 
  :HttpPort => 14712,
  :HttpsPort => 14713,
  :AllowIPs => ["127.0.0.1" ])
irc_publisher = IRCPublisher.new(@hub, "irc.codehaus.org", '#dce2e', ShortTextTemplate.new)
irc_publisher.handle = "server"
irc_publisher.start

@socket_trigger.join 

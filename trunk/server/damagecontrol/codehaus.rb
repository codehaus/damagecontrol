#!/usr/bin/env ruby

$damagecontrol_home = File::expand_path("#{File.dirname(__FILE__)}/../..") 
$:.push("#{$damagecontrol_home}/server")

require 'damagecontrol/DamageControlServer'

include DamageControl

buildRoot = File.expand_path("~/build")
#buildRoot = File.expand_path(".") 

server = DamageControlServer.new(
  :RootDir => buildRoot,
  :SocketTriggerPort => 4711, 
  :HttpPort => 4712,
  :HttpsPort => 4713,
  :AllowIPs => [ "127.0.0.1", "64.7.141.17" ])

def server.logging_level
  #Logging.debug
  Logging.quiet
end

def server.init_build_executors
  build_scheduler.add_executor(BuildExecutor.new(hub, build_history_repository, project_directories))
  build_scheduler.add_executor(BuildExecutor.new(hub, build_history_repository, project_directories))
end

def server.init_custom_components
  
  require 'damagecontrol/publisher/IRCPublisher'
  require 'damagecontrol/template/ShortTextTemplate'
  component(:irc_publisher, IRCPublisher.new(hub, "irc.codehaus.org", '#damagecontrol', ShortTextTemplate.new))
  
 # require 'damagecontrol/publisher/GraphPublisher'
 # component(:graph_publisher, GraphPublisher.new(hub, project_directories, build_history_repository))
  
  require 'damagecontrol/publisher/EmailPublisher'
  require 'damagecontrol/template/HTMLTemplate'
  component(:email_publisher, EmailPublisher.new(hub, ShortTextTemplate.new, HTMLTemplate.new, "dcontrol@builds.codehaus.org"))
  
  require 'damagecontrol/core/SelfUpgrader'
  component(:self_upgrader, SelfUpgrader.new(hub))
  
end

server.start.wait_for_shutdown

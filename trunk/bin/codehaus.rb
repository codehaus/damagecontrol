#!/usr/bin/env ruby

$damagecontrol_home = File::expand_path("#{File.dirname(__FILE__)}/..") 
$:.push("#{$damagecontrol_home}/server")

require 'damagecontrol/DamageControlServer'

include DamageControl

buildRoot = File.expand_path("~/build")
#buildRoot = File.expand_path(".") 

server = DamageControlServer.new(
  :RootDir => buildRoot,
  :HttpPort => 4712,
  :HttpsPort => 4713,
  :AllowIPs => [ "127.0.0.1", "64.7.141.17" ],
  :PollingInterval => 5 * 60 # every five minutes (don't want to overload servers)
  :TrigXmlrpcUrl => "http://builds.codehaus.org:4712/private/xmlrpc",
  :DamageControlUrl => "http://builds.codehaus.org/"
  )

def server.logging_level
  Logging.debug
  #Logging.quiet
end

def server.init_build_executors
  build_scheduler.add_executor(BuildExecutor.new(hub, build_history_repository, project_directories))
  build_scheduler.add_executor(BuildExecutor.new(hub, build_history_repository, project_directories))
end

def server.init_custom_components
  
  require 'damagecontrol/publisher/IRCPublisher'
  component(:irc_publisher, IRCPublisher.new(hub, self, "irc.codehaus.org", '#damagecontrol', "short_text_build_result_with_link.erb"))
  
 # require 'damagecontrol/publisher/GraphPublisher'
 # component(:graph_publisher, GraphPublisher.new(hub, project_directories, build_history_repository))
  
  require 'damagecontrol/publisher/EmailPublisher'
  component(:email_publisher, EmailPublisher.new(hub, self, "short_text_build_result_with_link.erb", "short_html_build_result.erb", "dcontrol@builds.codehaus.org"))
  
  #require 'damagecontrol/core/SelfUpgrader'
  #component(:self_upgrader, SelfUpgrader.new(hub))
  
end

server.start.wait_for_shutdown
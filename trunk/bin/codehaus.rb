#!/usr/bin/env ruby

require 'damagecontrol/DamageControlServer'

include DamageControl

buildRoot = File.expand_path("~/build")

server = DamageControlServer.new(
  :RootDir => buildRoot,
  :HttpPort => 4712,
  :HttpsPort => 4713,
  :AllowIPs => [ "127.0.0.1", "64.7.141.17" ],
  :AccessLog => File.expand_path("~/access.log"),
  :PollingInterval => 1 * 60, # every 1 minutes (don't want to overload servers)
  :TrigXmlrpcUrl => "http://builds.codehaus.org:4712/private/xmlrpc",
  :ExternalWebUrl => "http://builds.codehaus.org/damagecontrol"
  )

def server.logging_level
  Logging.debug
  #Logging.quiet
end

def server.init_build_executors
  build_scheduler.add_executor(BuildExecutor.new('Jon', hub, project_config_repository, build_history_repository))
  build_scheduler.add_executor(BuildExecutor.new('Aslak', hub, project_config_repository, build_history_repository))
end

def server.init_custom_components
  
  require 'damagecontrol/publisher/IRCPublisher'
#  component(:irc_publisher, IRCPublisher.new(hub, "irc.codehaus.org", '#damagecontrol', "short_text_build_result_with_link.erb"))
  
 # require 'damagecontrol/publisher/GraphPublisher'
 # component(:graph_publisher, GraphPublisher.new(hub, project_directories, build_history_repository))
  
  require 'damagecontrol/publisher/EmailPublisher'
  component(:email_publisher, EmailPublisher.new(hub, build_history_repository,
    :SubjectTemplate => "short_text_build_result.erb", 
    :BodyTemplate => "short_html_build_result.erb", 
    :FromEmail => "dcontrol@builds.codehaus.org"))
  
end

server.start.wait_for_shutdown
#!/usr/bin/env ruby

$damagecontrol_home = File::expand_path("#{File.dirname(__FILE__)}/..")
$:.push("#{$damagecontrol_home}/server")

require 'damagecontrol/DamageControlServer'

include DamageControl

server = DamageControlServer.new(
  :RootDir => "#{$damagecontrol_home}/work",
  :HttpPort => 4712
  :PollingInterval => 60 # specified in seconds
  # to allow access only from localhost then uncomment line below (when running behind an Apache proxy for example)
  #:AllowIPs => [ "127.0.0.1" ],
  )

def server.init_build_executors
  build_scheduler.add_executor(BuildExecutor.new(hub, build_history_repository, project_directories))
  # each BuildExecutor can execute one build in parallel to the others
  # to enable additional parallel builds (for multiple projects) uncomment lines below
  # you can have as many BuildExecutors as your machine can take
  #build_scheduler.add_executor(BuildExecutor.new(hub, build_history_repository, project_directories))
end

def server.init_custom_components

  # you can initialize custom or non-standard components below (examples provided)
  
  #require 'damagecontrol/publisher/IRCPublisher'
  #require 'damagecontrol/template/ShortTextTemplate'
  #component(:irc_publisher, IRCPublisher.new(hub, "irc.codehaus.org", '#damagecontrol', ShortTextTemplate.new))
  
  #require 'damagecontrol/publisher/EmailPublisher'
  #require 'damagecontrol/template/HTMLTemplate'
  #component(:email_publisher, EmailPublisher.new(hub, ShortTextTemplate.new, HTMLTemplate.new, "dcontrol@builds.codehaus.org"))
  
end

server.start.wait_for_shutdown

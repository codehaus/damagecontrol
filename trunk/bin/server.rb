#!/usr/bin/env ruby

require 'damagecontrol/DamageControlServer'

include DamageControl

server = DamageControlServer.new(
  :RootDir => "#{$damagecontrol_home}/work",
  :HttpPort => 4712,
  :PollingInterval => 60 # specified in seconds
  # to allow access only from localhost then uncomment line below (when running behind an Apache proxy for example)
  #:AllowIPs => [ "127.0.0.1" ],
  )

def server.init_build_executors
  build_scheduler.add_executor(BuildExecutor.new(hub, build_history_repository))
  # each BuildExecutor can execute one build in parallel to the others
  # to enable additional parallel builds (for multiple projects) uncomment lines below
  # you can have as many BuildExecutors as your machine can take
  #build_scheduler.add_executor(BuildExecutor.new(hub, build_history_repository, project_directories))
end

def server.init_custom_components

  # you can initialize custom or non-standard components below (examples provided)
  
  #require 'damagecontrol/publisher/IRCPublisher'
  #component(:irc_publisher, IRCPublisher.new(hub, "some.irc.server", '#somechannel', "short_text_build_result_with_link.erb"))
  
  #require 'damagecontrol/publisher/EmailPublisher'
  #component(:email_publisher, EmailPublisher.new(hub, build_history_repository,
  #  :SubjectTemplate => "short_text_build_result.erb", 
  #  :BodyTemplate => "short_html_build_result.erb",
  #  :FromEmail => "damagecontrol@mydomain.com",
  #  :MailServerHost => "localhost",
  #  :MailServerPort => 25)
  
end

class MyReport < Report
  def id
    "my"
  end
  
  def available?
    selected_build.project_name == "damagecontrolled"
  end
  
  def content
    "Hello Mike and Ajit!\n#{selected_build.inspect}"
  end
end

def server.report_classes
  super + [ MyReport ]
end

server.start.wait_for_shutdown

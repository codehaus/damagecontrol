#!/usr/bin/env ruby

require 'damagecontrol/DamageControlServer'

include DamageControl

buildRoot = File.expand_path("~/build")
#buildRoot = File.expand_path(".") 

server = DamageControlServer.new(
  :RootDir => buildRoot,
  :HttpPort => 4712,
  :HttpsPort => 4713,
  :AllowIPs => [ "127.0.0.1", "64.7.141.17" ],
  :AccessLog => File.expand_path("~/access.log"),
  :PollingInterval => 0, #5 * 60, # every five minutes (don't want to overload servers)
  :TrigXmlrpcUrl => "http://builds.codehaus.org:4712/private/xmlrpc",
  :ExternalWebUrl => "http://builds.codehaus.org"
  )

def server.logging_level
  Logging.debug
  #Logging.quiet
end

def server.init_build_executors
  build_scheduler.add_executor(BuildExecutor.new('executor1', hub, project_directories, build_history_repository))
  build_scheduler.add_executor(BuildExecutor.new('executor2', hub, project_directories, build_history_repository))
end


class WarningServer
  def start
    @t = Thread.new do
      begin
        @server = TCPServer.new(4711)
        while (socket = @server.accept)
          socket.print("WARNING WARNING WARNING WARNING\r\n")
          socket.print("DamageControl does not support trigging over port 4711 anymore\r\n")
          socket.print("DamageControlled projects are now configured\r\n")
          socket.print("via http://builds.codehaus.org/private/dashboard\r\n")
          socket.print("Contact Jon or Aslak on #codehaus on irc.codehaus.org or\r\n")
          socket.print("jon@tirsen.com or aslak@thoughtworks.net\r\n")
          socket.print("to get a password so you can reconfigure your project.\r\n")
          socket.print("Sorry for the inconvenience.\r\n")
          socket.close
        end
      rescue => e
      ensure
        puts "Stopped SocketTrigger listening on port #{port}"
      end
    end
  end
  
  def shutdown
    begin
      @server.shutdown
    rescue => e
    end
    begin
      @t.kill
    rescue => e
    end
  end
end

def server.init_custom_components
  
  component(:warning_server, WarningServer.new)
  
  require 'damagecontrol/publisher/IRCPublisher'
  component(:irc_publisher, IRCPublisher.new(hub, "irc.codehaus.org", '#damagecontrol', "short_text_build_result_with_link.erb"))
  
 # require 'damagecontrol/publisher/GraphPublisher'
 # component(:graph_publisher, GraphPublisher.new(hub, project_directories, build_history_repository))
  
  require 'damagecontrol/publisher/EmailPublisher'
  component(:email_publisher, EmailPublisher.new(hub, build_history_repository,
    :SubjectTemplate => "short_text_build_result.erb", 
    :BodyTemplate => "short_html_build_result.erb", 
    :FromEmail => "dcontrol@builds.codehaus.org"))
  
end

server.start.wait_for_shutdown
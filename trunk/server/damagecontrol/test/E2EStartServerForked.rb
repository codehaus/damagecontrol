require 'damagecontrol/DamageControlServer'

include DamageControl

server = DamageControlServer.new(
  :RootDir => ARGV[0],
  :HttpPort => 14712,
  :HttpsPort => 14713,
  :AllowIPs => ["127.0.0.1" ])

def server.logging_level
  #Logging.debug
  Logging.quiet
end

def server.init_custom_components
  require 'damagecontrol/publisher/IRCPublisher'
  component(:irc_publisher, IRCPublisher.new(hub, self, "irc.codehaus.org", '#dce2e', "short_text_build_result.erb"))
  irc_publisher.handle = "server"
end

server.start.wait_for_shutdown

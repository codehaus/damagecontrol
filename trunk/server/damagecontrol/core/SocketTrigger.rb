require 'socket'
require 'yaml'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildBootstrapper'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/util/Logging'

module DamageControl

  class HostVerifier
    def initialize(allowed_client_ips=["127.0.0.1"], allowed_client_hostnames=["localhost"])
      @allowed_client_hostnames = allowed_client_hostnames
      @allowed_client_ips = allowed_client_ips      
    end

    def allowed?(client_hostname, client_ip)
      !@allowed_client_hostnames.index(client_hostname).nil? || !@allowed_client_ips.index(client_ip).nil?
    end
  end

  # This class listens for incoming connections. For each incoming
  # connection it will read one line of payload. The payload is parsed
  # into a Build object which is then wrapped in a BuildRequestEvent
  # and sent to the channel.
  #
  # Then it closes the connection and listens for new connections.
  #
  class SocketTrigger
  
    include FileUtils
    include Logging

    attr_accessor :port
    attr_accessor :host_verifier
    
    def initialize(channel, port=4711, host_verifier = HostVerifier.new)
      @channel = channel
      @port = port
      @host_verifier = host_verifier
      
      @build_bootstrapper = BuildBootstrapper.new
    end
    
    def process_payload(build_yaml)
      build = @build_bootstrapper.create_build(build_yaml)
      build.status = Build::QUEUED
      @channel.publish_message(BuildRequestEvent.new(build))
    end

    def do_accept(socket)
      begin
        client_hostname = socket.peeraddr[2]
        client_ip = socket.peeraddr[3]
        logger.info("request from #{client_hostname} / #{client_ip}")

        if(!host_verifier.allowed?(client_hostname, client_ip))
          logger.error("request from disallowed host #{client_hostname} / #{client_ip}")
          socket.print("This DamageControl server doesn't allow connections from #{client_hostname} / #{client_ip}\r\n")
          return
        end

        payload = ""
        socket.each do |line|
          if(line.chomp == "...")
            break
          else
            payload << line
          end
        end
        logger.info("payload:")
        logger.info(payload)
        begin
          socket.print("DamageControl server on #{get_ip} got message from #{client_ip}\r\n")
          socket.print("http://damagecontrol.codehaus.org/\r\n")
          socket.print("http://builds.codehaus.org/\r\n")
          socket.print("irc://irc.codehaus.org/damagecontrol/\r\n")
          process_payload(payload)
        rescue => e
          logger.error("Error processing socket payload: #{format_exception(e)}")
          socket.print("DamageControl exception:\n")
          socket.print(e.message)
          socket.print("DamageControl config:\n")
          socket.print(payload)
        end
      ensure
        socket.close
      end
    end
    
    def print_error(e)
      $stderr.print e
      $stderr.print "\n"
      $stderr.print e.backtrace.join("\n")
      $stderr.print "\n"
    end

    def start
      Thread.new do
        begin
          @server = TCPServer.new(port)
          # doesn't seem to work properly
          #at_exit { @server.shutdown }
          logger.info "#{self} listening on port #{port}"
          
          while (socket = @server.accept)
            do_accept(socket)
          end
        rescue => e
          logger.error(format_exception(e))
        ensure
          puts "Stopped SocketTrigger listening on port #{port}"
        end
      end
    end
    
    def shutdown
      begin
        @server.shutdown
      rescue => e
        # fails if socket is closed, which it might be. just ignore that.
        logger.error(format_exception(e))
      end
    end
    
    def get_ip
      IPSocket.getaddress(Socket.gethostname)
    end
    
  end
end


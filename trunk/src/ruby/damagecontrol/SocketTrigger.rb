require 'socket'
require 'yaml'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/Build'
require 'damagecontrol/BuildBootstrapper'
require 'damagecontrol/FileUtils'

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

    attr_accessor :port
    attr_accessor :host_verifier
    
    def initialize(channel, port=4711, host_verifier = HostVerifier.new)
      @channel = channel
      @port = port
      @host_verifier = host_verifier
      
      @build_bootstrapper = BuildBootstrapper.new
    end
    
    def process_payload(payload)
      build = @build_bootstrapper.create_build(payload)
      @channel.publish_message(BuildRequestEvent.new(build))
    end

    def do_accept(socket)
      begin
        client_hostname = socket.peeraddr[2]
        client_ip = socket.peeraddr[3]
        if(host_verifier.allowed?(client_hostname, client_ip))
          payload = ""
          socket.each do |line|
            if(line.chomp == "...")
              break
            else
              payload << line
            end
          end
          begin
            process_payload(payload)
            socket.print("DamageControl server on #{get_ip} got message from #{client_ip}\r\n")
            socket.print("http://damagecontrol.codehaus.org/\r\n")
          rescue => e
            print_error(e)
            socket.print("DamageControl exception:\n")
            socket.print(e.message)
            socket.print("DamageControl config:\n")
            socket.print(payload)
          end
        else
          socket.print("This DamageControl server doesn't allow connections from #{client_hostname} / #{client_ip}\r\n")
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
      Thread.new {
        begin
          @server = TCPServer.new(port)
          puts "Starting SocketTrigger listening on port #{port}"
          $stdout.flush
          
          while (socket = @server.accept)
            do_accept(socket)
          end
        rescue => e
          print_error(e)
          @error = e
        ensure
          puts "Stopped SocketTrigger listening on port #{port}"
        end
      }
    end
    
    def get_ip
      # cache ip to avoid starting a new process each time
      @myip = fetch_ip if @myip.nil?
      @myip
    end
    
    def fetch_ip
"beaver.codehaus.org"
#      result = if windows?
#        get_ip_from_ipconfig_exe_output(`ipconfig.exe`)
#      else
#        `/sbin/ifconfig eth0|grep inet|cut -d : -f 2|cut -d \  -f 1`.chomp
#      end
#      result = "(unknown)" unless $?
#      result
    end
    
    def get_ip_from_ipconfig_exe_output(ipconfig_output)
      if ipconfig_output =~ /IP Address(. )*: (.*)$/
        $2.chomp
      else
        "(unknown)"
      end
    end
    

  end
end


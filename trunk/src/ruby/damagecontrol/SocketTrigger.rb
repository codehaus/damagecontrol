require 'socket'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/Build'

module DamageControl

  # This class listens for incoming connections. For each incoming
  # connection it will read one line of payload. The payload is parsed
  # into a Build object which is then wrapped in a BuildRequestEvent
  # and sent to the channel.
  #
  # Then it closes the connection and listens for new connections.
  #
  class SocketTrigger
  
    attr_accessor :port
    
    def initialize(channel, port=4711, allowed_client_ips=["127.0.0.1"], allowed_client_hostnames=["localhost"])
      @channel = channel
      @port = port
      @allowed_client_hostnames = allowed_client_hostnames
      @allowed_client_ips = allowed_client_ips
    end
    
    # Creates a trigger command that is compatible with the create_build
    # method. This method is used to create a command string that can
    # be installed in various SCM's trigger mechanisms.
    #
    # @param project_name a logical name for the project (no spaces please)
    # @param path full SCM spec (example: :local:/cvsroot/picocontainer:pico)
    # @param build_command_line command line that will run the build
    # @param host where the dc server is running
    # @param port where the dc server is listening
    # @param replace_string what to replace "/" with (needed for CVS on windows)
    def trigger_command(project_name, spec, build_command_line, nc_command, dc_host, dc_port, path_sep="/")
      "echo #{project_name},#{spec.gsub('/', path_sep)},#{build_command_line}|#{nc_command} #{dc_host} #{dc_port}"
    end

    def create_build(build_spec)
      project_name, scm_spec, build_command_line = build_spec.split(",")
      Build.new(project_name.chomp, scm_spec.chomp, build_command_line.chomp)
    end

    def do_accept(payload)
      build = create_build(payload)
      @channel.publish_message(BuildRequestEvent.new(build))
    end
    
    def start
      Thread.new {
        begin
          @server = TCPServer.new(port)
          puts "Starting SocketTrigger listening on port #{port}"
          $stdout.flush
          
          while (socket = @server.accept)
            begin
              client_hostname = socket.addr[2]
              client_ip = socket.addr[3]
              if(allowed?(client_hostname, client_ip))
                payload = socket.gets
                do_accept(payload)
                socket.print("DamageControl got your message\r\n")
                socket.print("http://damagecontrol.codehaus.org/\r\n")
              else
                socket.print("Connections are not allowed from #{client_ip}")
              end
            ensure
              socket.close
            end
          end
        rescue
          $stderr.print $!
          $stderr.print "\n"
          $stderr.print $!.backtrace.join("\n")
          $stderr.print "\n"
          @error = $!
        ensure
          puts "Stopped SocketTrigger listening on port #{port}"
        end
      }
    end
    
    def allowed?(client_hostname, client_ip)
      !@allowed_client_hostnames.index(client_hostname).nil? || !@allowed_client_ips.index(client_ip).nil?
    end
  end
end


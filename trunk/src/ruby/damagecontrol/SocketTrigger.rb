require 'socket'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/Hub'
require 'damagecontrol/BuildResult'

module DamageControl

  class SocketRequestEvent
    attr_reader :payload
    
    def initialize(payload)
      @payload = payload
    end
    
    def ==(other)
      other.is_a?(SocketRequestEvent) && \
        @payload == other.payload
    end
  end

  # This class listens for incoming connections. For each connection
  # it reads one line of payload which is sent to the hub wrapped in
  # a SocketRequestEvent object. Then it closes the connection and
  # listens for new connections.
  #
  # Consumes:
  # Emits: BuildRequestEvent
  #
  class SocketTrigger
  
    attr_accessor :port
    
    def initialize(hub, root_dir, port=4711)
      @hub = hub
      @root_dir = root_dir
      @port = port
    end
    
    # creates a trigger command
    #
    # @param project_name a human readable name for the module
    # @param path full SCM spec (example: :local:/cvsroot/picocontainer:pico)
    # @param build_command_line command line that will run the build
    # @param relative_path relative path in dc's checkout where build
    #        command will be executed from
    # @param host where the dc server is running
    # @param port where the dc server is listening
    # @param replace_string what to replace "/" with (needed for CVS on windows)
    def trigger_command(project_name, spec, build_command_line, relative_path, nc_command, dc_host, dc_port, replace_string="/")
      "echo #{project_name},#{spec.gsub('/', replace_string)},#{build_command_line},#{relative_path}|#{nc_command} #{dc_host} #{dc_port}"
    end

    def bootstrap_build(build_spec, root_dir)
      project_name, scm_spec, build_command_line, build_path = build_spec.split(",")
      BuildResult.new(project_name.chomp, scm_spec.chomp, build_command_line.chomp, build_path.chomp, root_dir.chomp)
    end

    def do_accept(payload)
      build = bootstrap_build(payload, @root_dir);
      @hub.publish_message(BuildRequestEvent.new(build))
    end
    
    def start
      Thread.new {
        begin
          @server = TCPServer.new(port)
          puts "Starting SocketTrigger listening on port #{port}"
          $stdout.flush
          
          while (session = @server.accept)
            begin
              payload = session.gets
              do_accept(payload)
              session.print("got your message\r\n\r\n")
            ensure
              session.close()
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

  end
end


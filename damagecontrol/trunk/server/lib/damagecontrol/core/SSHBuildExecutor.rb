require 'damagecontrol/core/BuildExecutor'

module DamageControl
	class SSHBuildExecutor < BuildExecutor
		def initialize(host, username, channel, project_config_repository, build_history_repository)
			super("#{username}@#{host}", channel, project_config_repository, build_history_repository)
			@host = host
			@user = username
		end
    
    def execute
      current_build.status = Build::BUILDING
      @channel.put(BuildStateChangedEvent.new(current_build))

      # set up some environment variables the build can use
      environment = { 
        "DAMAGECONTROL_BUILD_LABEL" => current_build.label.to_s, # DC style
        "PKG_BUILD" => current_build.label.to_s # Seems to be Rake (and other build systems?) common convention..
      }
      unless current_build.changesets.nil?
#        environment["DAMAGECONTROL_CHANGES"] = 
#          current_build.changesets.format(CHANGESET_TEXT_FORMAT, Time.new.utc)
      end
      stdout(current_build.build_command_line)
      
      # -t -t forces an interactive terminal, even if it is really noninteractive
      # this allows us to write commands to the standard input, but it also
      # leaves us with some gimmicks, only interactive terminals can cope with
      # like colors and ^H characters
      @build_process.execute("ssh -t -t -l #{@user} #{@host}") do |stdin, stdout, stderr|
        threads = []
        environment_thread = Thread.new {
          # This thread fills the stdin. The first thing to do is to set the
          # environment variables
          sleep(20)
          stdin << "echo \"DAMAGECONTROL::INIT ENVIRONMENT\""
          stdin << "export DAMAGECONTROL_BUILD_LABEL=#{current_build.label.to_s}"
          stdin << "export PKG_BUILD=#{current_build.label.to_s}"
          # stdin << "#{current_build.build_command_line}\n"
          stdin << "echo \"DAMAGECONTROL::INIT ENVIRONMENT OK\""
        }
        
        checkout_thread = Thread.new {
          Thread.stop
          current_build.status = Build::CHECKING_OUT
          @channel.put(BuildStateChangedEvent.new(current_build))
          stdin << "echo \"DAMAGECONTROL::CHECKOUT\""
          stdin << "svn co http://localhost/svn" #FIXME: use the correct checkout command
          stdin << "echo \"DAMAGECONTROL::CHECKOUT STATUS\" $?"
        }
        
        build_thread = Thread.new {
          Thread.stop
          current_build.status = Build::BUILDING
          @channel.put(BuildStateChangedEvent.new(current_build))
          stdin << "echo \"DAMAGECONTROL::BUILD\""
          stdin << "fortune" #FIXME: use the correct build command
          stdin << "echo \"DAMAGECONTROL::BUILD STATUS\" $?"
        }
        
        exit_thread = Thread.new {
          Thread.stop
          stdin << "exit"
        }
        
        threads << environment_thread
        
        threads << Thread.new { 
          stdout.each_line { |line|
            if (!line.match(/^DAMAGECONTROL::.*$/)) {
              report_progress(line)
            } else {
              # handle command messages
              if (line.match(/^DAMAGECONTROL::CHECKOUT STATUS 0$/)) {
                # checkout was successful, start the build process
                build_thread.wakeup
              } elsif (line.match(/^DAMAGECONTROL::INIT ENVIRONMENT OK$/)) {
                # start the checkout process
                checkout_thread.wakeup
              } elsif (line.match(/^DAMAGECONTROL::BUILD STATUS 0$/)) {
                # build successful, set status and disconnect
                current_build.status = Build::SUCCESSFUL
                @channel.put(BuildStateChangedEvent.new(current_build))
                exit_thread.wakeup
              } elsif (line.match(/^DAMAGECONTROL::CHECKOUT STATUS .*$/)) {
                # checkout failed, set status and disconnect
                current_build.status = Build::FAILED
                @channel.put(BuildStateChangedEvent.new(current_build))
                exit_thread.wakeup
              } elsif (line.match(/^DAMAGECONTROL::BUILD STATUS .*$/)) {
                # build failed, set status and disconnect
                current_build.status = Build::FAILED
                @channel.put(BuildStateChangedEvent.new(current_build))
                exit_thread.wakeup
              }
              #
            }
          }
        }
        
        threads << Thread.new { stderr.each_line {|line| report_error(line) } }
        threads.each{|t| t.join}
      end		
	end
end

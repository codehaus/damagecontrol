require 'damagecontrol/core/BuildExecutor'

module DamageControl
	class SSHBuildExecutor < BuildExecutor
		def initialize(host, username, channel, project_directories, build_history_repository)
			super("#{username}@#{host}", channel, project_directories, build_history_repository)
			@host = host
			@user = username
		end
		
		def execute
			#puts current_build.build_command_line = "ssh #{@user}@#{@host} \"#{current_build.build_command_line}\""

			current_build.status = Build::BUILDING
      @channel.put(BuildStateChangedEvent.new(current_build))

      # set up some environment variables the build can use
      environment = { "DAMAGECONTROL_BUILD_LABEL" => current_build.potential_label.to_s }
			
			
			
      unless current_build.changesets.nil?
        environment["DAMAGECONTROL_CHANGES"] = 
          current_build.changesets.format(CHANGESET_TEXT_FORMAT, Time.new.utc)
      end
      report_progress(current_build.build_command_line)
      begin
        @build_process = Pebbles::Process.new
        @build_process.working_dir = checkout_dir
        @build_process.environment = environment
				# -t -t forces an interactive terminal, even if it is really noninteractive
				# this allows us to write commands to the standard input, but it also
				# leaves us with some gimmicks, only interactive terminals can cope with
				# like colors and ^H characters
        @build_process.execute("ssh -t -t -l #{@user} #{@host}") do |stdin, stdout, stderr|
          threads = []
					threads << Thread.new { 
						sleep(20)
						stdin << "#{current_build.build_command_line}\n"
						stdin << "exit\n"
					}
          threads << Thread.new { stdout.each_line {|line| report_progress(line) } }
          threads << Thread.new { stderr.each_line {|line| report_error(line) } }
          threads.each{|t| t.join}
        end
        current_build.status = Build::SUCCESSFUL
        @channel.put(BuildStateChangedEvent.new(current_build))
      rescue Exception => e
        logger.error("build failed: #{format_exception(e)}")
        report_error(format_exception(e))
        if was_killed?
          current_build.status = Build::KILLED
        else
          current_build.status = Build::FAILED
        end
        @channel.put(BuildStateChangedEvent.new(current_build))
      end

      # set the label
      if(current_build.successful?)
        current_scm_label = current_scm.label(checkout_dir)
        if(current_scm_label)
          current_build.label = current_scm_label
        else
          current_build.label = current_build.potential_label
        end
      end
    end
		
	end
end

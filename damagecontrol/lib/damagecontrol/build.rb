require 'rscm/path_converter'
require 'damagecontrol/directories'
require 'damagecontrol/project'

module DamageControl
  # Represents build-related data organised in the following file structure:
  #
  # File structure:
  #
  #   .damagecontrol/
  #     SomeProject/
  #       project.yaml
  #       checkout/
  #       changesets/
  #         2802/
  #           changeset.yaml         (serialised ChangeSet object)
  #           diffs/                 (serialised diff files)
  #           builds/                
  #             2005280271234500/    (timestamp of build start)
  #               stdout.log
  #               stderr.log
  #               artifacts/
  #
  class Build
    attr_reader :time
  
    # Creates a new Build for a +project+'s +changeset+, created at +time+.
    def initialize(project_name, changeset_identifier, time, build_reason)
      @project_name, @changeset_identifier, @time, @build_reason = project_name, changeset_identifier, time, build_reason
    end

    # Our unique id within the changeset
    def identifier
      time.ymdHMS
    end

    # Our associated project
    def project
      Project.load(@project_name)
    end
    
    # Our associated changeset
    def changeset
      project.changeset(@changeset_identifier)
    end
    
    # Executes +command+ with the environment variables +env+ and persists the command for future reference.
    # This will prevent the same build from being executed in the future.
    def execute(command, env={})
      command_file = Directories.build_command_file(@project_name, @changeset_identifier, @time)
      raise BuildException.new("This build has already been executed and cannot be re-executed. It was executed with '#{File.open(command_file).read}'") if File.exist?(command_file)
      FileUtils.mkdir_p(File.dirname(command_file))
      File.open(command_file, "w") do |io|
        io.write(command)
      end
      command_line = "#{command} > #{stdout} 2> #{stderr}"

      begin
        with_working_dir(checkout_dir) do
          env.each {|k,v| ENV[k]=v}
          Log.info "Executing '#{command_line}'"
          Log.info "Execution environment:"
          ENV.each {|k,v| Log.info("#{k}=#{v}")}
          IO.popen(command_line) do |io|
            File.open(pid_file, "w") do |pid_io|
              pid_io.write(pid)
            end
            
            # there is nothing to read, since we're redirecting to file,
            # but we still need to read in order to block till process id done.
            io.read
          end
        end
      ensure
        exit_code = $? >> 8
        File.open(exit_code_file, "w") do |io|
          io.write(exit_code)
        end
      end
    end
    
    # Returns the exit code of the build process, or nil if the process was killed
    def exit_code
      if(File.exist?(exit_code_file))
        File.read(exit_code_file).to_i
      else
        nil
      end
    end

    # Returns the pid of the build process
    def pid
      File.read(pid_file).to_i
    end
    
    def kill
      Process.kill("SIGHUP", pid)
    end

    def stdout
      Directories.stdout(@project_name, @changeset_identifier, @time)
    end

    def stderr
      Directories.stderr(@project_name, @changeset_identifier, @time)
    end

  private
  
    def checkout_dir
      Directories.checkout_dir(@project_name)
    end
  
    def exit_code_file
      Directories.build_exit_code_file(@project_name, @changeset_identifier, @time)
    end
    
    def pid_file
      Directories.build_pid_file(@project_name, @changeset_identifier, @time)
    end
    
  end
  
  class BuildException < Exception
  end
end
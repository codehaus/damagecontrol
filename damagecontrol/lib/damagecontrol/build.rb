require 'rscm/path_converter'
require 'damagecontrol/directories'

module DamageControl
  # File structure
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
  
    attr_reader :project, :changeset, :time
  
    # Creates a new Build for a +project+'s +changeset+, created at +time+.
    def initialize(project_name, changeset_identifier, time)
      @project_name, @changeset_identifier, @time = project_name, changeset_identifier, time
    end
    
    # Executes the +cmd+ command for this build and persists the command for future reference.
    # This will prevent the same build from being executed in the future.
    def execute(command)
      command_file = Directories.build_command_file(@project_name, @changeset_identifier, @time)
      raise BuildException.new("This build has already been executed and cannot be re-executed. It was executed with '#{File.open(command_file).read}'") if File.exist?(command_file)
      FileUtils.mkdir_p(File.dirname(command_file))
      File.open(command_file, "w") do |io|
        io.write(command)
      end
      stderr = Directories.stderr(@project_name, @changeset_identifier, @time)
      stdout = Directories.stdout(@project_name, @changeset_identifier, @time)
      command_line = "#{command} > #{stdout} 2> #{stderr}"

      begin
        with_working_dir(checkout_dir) do
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
      File.read(exit_code_file).to_i
    end

    # Returns the pid of the build process
    def pid
      File.read(pid_file).to_i
    end
    
    def kill
      Process.kill("SIGHUP", pid)
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
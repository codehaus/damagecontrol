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
    end
  end
  
  class BuildException < Exception
  end
end
# Represents the execution and status of a build for a particular Revision. Has the following attributes:
#
# * command - the command that was executed (taken from Project)
# * env - the environment variables at the time of execution
# * stdout - standard output
# * stderr - standard error
# * pid - the process id
# * exitstatus - the exit code of the build command
# * reason - the reason for the build
# * status - One of: nil (pending), Build::Executing, Build::Successful, Build::Fixed, Build::Broken, Build::RepeatedlyBroken
#
# A build can only be executed once, and will raise an exception if it has already been executed.
# In order to reexecute a build, create a new instance (via Revision.builds.create)
#
class Build < ActiveRecord::Base
  SCM_POLLED = "SCM_POLLED"
  SCM_TRIGGERED = "SCM_TRIGGERED"
  MANUALLY_TRIGGERED = "MANUALLY_TRIGGERED"
  SUCCESSFUL_DEPENDENCY = "SUCCESSFUL_DEPENDENCY"

  acts_as_list :scope => :revision
  belongs_to :revision
  has_many :artifacts
  serialize :env
  serialize :state

  validates_inclusion_of :reason, :in => [SCM_POLLED, SCM_TRIGGERED, MANUALLY_TRIGGERED, SUCCESSFUL_DEPENDENCY]

  # A short description of the reason for this build
  def reason_description
    # TODO: use case - can't remember syntax
    if(reason == SCM_POLLED)
      "Commit by #{revision.developer}"
    end
  end
  
  # The previous build. First looks within the same revision. If none are found,
  # looks in previous revision that has at least one build and takes the last from there.
  def previous
    higher_item
  end
  
  # Alias for +revision.project+ (mainly to simplify testing,
  # since it reduces coupling)
  def project
    self.revision.project
  end

  def successful?
    exitstatus == 0
  end

  # Executes this build and persists results. 
  # The following steps occur (in a forked subprocess) when calling this method:
  #
  # 1) The revision for this build is checked out
  # 2) The project's build command is executed
  # 3) The project is notified via Project.build_complete when the build is complete
  #
  def execute!(timepoint=Time.now.utc)
    raise "Alreade executed" if exitstatus
    self.state = Executing.new
    self.timepoint = timepoint
    self.command = self.revision.project.build_command
    self.env = {
      "DAMAGECONTROL_BUILD_LABEL" => revision.identifier.to_s,
      "PKG_BUILD" => revision.identifier.to_s,
      "DAMAGECONTROL_CHANGED_FILES" => revision.revision_files.collect{|f| f.path}.join(',')
    }
    save
    project.build_executing(self)
    
    # Do all the hard work in a sub process. Dir.chdir is global in ruby.
    pid = fork do
      # Make sure the working copy is in sync
      revision.sync_working_copy
      
      env.each{|k,v| ENV[k]=v}
      Dir.chdir(revision.project.build_dir) do
        begin
          redirected_cmd = "#{command} > #{revision.project.stdout_file} 2> #{revision.project.stderr_file}"
          logger.info "Executing build for #{revision.project.name}'s revision #{revision.identifier}" if logger
          exec redirected_cmd
        rescue Errno::ENOENT => e
          File.open(stderr_file.path) {|io| self.stderr = e.message}
          exit! 1
        end
      end
    end
    
    # Wait for the subprocess to complete and publish the result
    self.pid, status = Process.waitpid2(pid)
    self.exitstatus = status.exitstatus
    determine_state
    File.open(revision.project.stdout_file) {|io| self.stdout = io.read}
    File.open(revision.project.stderr_file) {|io| self.stderr = io.read}

    save
    
    project.build_complete(self)
    
    self.exitstatus
  end

  # :nodoc:
  def determine_state
    self.state = previous_state.send(successful? ? :succeed : :fail)
  end

private 

  # The state of the previous build, or Broken if
  # there is no previous build.
  def previous_state
    prev = previous
    prev ? prev.state : Successful.new
  end  
  
  class Executing
    def description
      "Executing"
    end
  end

  class Successful
    def succeed
      Successful.new
    end
    def fail
      Broken.new
    end
    def description
      "Successful"
    end
  end

  class Fixed < Successful
    def description
      "Fixed"
    end
  end

  class Broken
    def succeed
      Fixed.new
    end
    def fail
      RepeatedlyBroken.new
    end
    def description
      "Broken"
    end
  end

  class RepeatedlyBroken < Broken
    def description
      "Repeatedly broken"
    end
  end
  
  STATES = [Executing.new, Successful.new, Fixed.new, Broken.new, RepeatedlyBroken.new]

end

require 'tempfile'

# Represents the execution and status of a build for a particular Revision. Has the following properties:
#
# * command - the command that was executed
# * env - the environment variables at the time of execution
# * stdout - standard output
# * stderr - standard error
# * pid - the process id
# * exitstatus - the result of the execution
# * timepoint - the time when the execution started
#
# A build can only be executed once, and will raise an exception if it has already been executed.
# In order to reexecute a build, create a new instance (via Revision.builds.create)
#
class Build < ActiveRecord::Base
  belongs_to :revision
  serialize :env

  REQUESTED = "REQUESTED"
  EXECUTING = "EXECUTING"
  COMPLETE = "COMPLETE"
  PUBLISHED = "PUBLISHED"

  # Alias for +revision.project+ (mainly to simplify testing,
  # since it reduces coupling)
  def project
    self.revision.project
  end

  def before_create
    self.status = REQUESTED
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
  def execute!(env, timepoint=Time.now.utc)
    # TODO: we need to use proctable and look up the pid.
    raise "Already executed" if self.status != REQUESTED
    
    self.timepoint = timepoint
    self.command = self.revision.project.build_command
    self.env = env
    
    stdout_file = Tempfile.new("dc_build_stdout_#{id}.")
    stderr_file = Tempfile.new("dc_build_stderr_#{id}.")
    
    # Do all the hard work in a sub process. Dir.chdir is global in ruby.
    pid = fork do
      # Make sure the working copy is in sync
      revision.sync_working_copy
      
      # Execute the build with the given environment variables.
      env.each{|k,v| ENV[k]=v}
      env.merge!(ENV)
      Dir.chdir(revision.project.build_dir) do
        begin
          redirected_cmd = "#{command} > #{stdout_file.path} 2> #{stderr_file.path}"
          exec redirected_cmd
        rescue Errno::ENOENT => e
          File.open(stderr_file.path) {|io| self.stderr = e.message}
          exit! 1
        end
      end
    end
    
    # Wait for the subprocess to complete and publish the result
    self.pid, status = Process.waitpid2(pid)
    File.open(stdout_file.path) {|io| self.stdout = io.read}
    File.open(stderr_file.path) {|io| self.stderr = io.read}
    self.exitstatus = status.exitstatus
    self.status = COMPLETE
    save
    
    project.build_complete(self)
    
    self.exitstatus
  end

end

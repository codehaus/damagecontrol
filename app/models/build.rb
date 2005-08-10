# Represents the execution and status of a build for a particular Revision. Has the following attributes:
#
# * +command+ - The command that was executed (taken from Project)
# * +env+ - The environment variables at the time of execution
# * +stdout+ - Standard output
# * +stderr+ - Standard error
# * +pid+ - The process id
# * +exitstatus+ - The exit code of the build command
# * +reason+ - The reason for the build
# * +state+ - One of: nil (pending), Build::Executing, Build::Successful, Build::Fixed, Build::Broken, Build::RepeatedlyBroken
# * +create_time+ - The time the build was created (requested).
# * +begin_time+ - The time the build began.
# * +end_time+ - The time the build ended.
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
  belongs_to :triggering_build, :class_name => "Build"
  has_many :artifacts
  serialize :env
  serialize :state

  validates_inclusion_of :reason, :in => [SCM_POLLED, SCM_TRIGGERED, MANUALLY_TRIGGERED, SUCCESSFUL_DEPENDENCY]

  def before_create
    self.create_time = Time.now.utc
  end
  
  # The 'owner' of this build depends on the +reason+ for the build:
  #
  #   * SCM_POLLED => revision.developer
  #   * SCM_TRIGGERED => revision.developer
  #   * MANUALLY_TRIGGERED => revision.developer
  #   * SUCCESSFUL_DEPENDENCY => other_build.revision.developer
  def owner
    case reason
      when SCM_POLLED then revision.developer
      when SCM_TRIGGERED then revision.developer
      when MANUALLY_TRIGGERED then revision.developer # TODO: use user auth here!
      when SUCCESSFUL_DEPENDENCY then triggering_build.revision.project.name
    end
  end

  # A short description of the reason for this build
  def reason_description
    case reason
      when SCM_POLLED then "commit by #{revision.developer}"
      when SCM_TRIGGERED then "commit by #{revision.developer}"
      when MANUALLY_TRIGGERED then "manually triggered"
      when SUCCESSFUL_DEPENDENCY then "successful build of #{triggering_build.revision.project.name}"
    end
  end
  
  def stdout
    connection.select_one("SELECT data FROM build_logs WHERE id=#{stdout_id}")["data"]
  end

  def stderr
    connection.select_one("SELECT data FROM build_logs WHERE id=#{stderr_id}")["data"]
  end
  
  # The previous build. First looks within the same revision. If none are found,
  # gets project's latest build before ourself
  def previous
    h = higher_item
    h ? h : revision.project.builds(nil, begin_time)[0]
  end
  
  # The estimated duration of this build, or nil if it cannot be determined.
  def estimated_duration
    lb = revision.project.builds(true)[0]
    lb ? lb.duration : nil
  end
  
  # Duration of this build or nil if it isn't complete.
  def duration
    end_time ? end_time - begin_time : nil
  end
  
  # Alias for +revision.project+ (mainly to simplify testing,
  # since it reduces coupling)
  def project #:nodoc:
    self.revision.project
  end

  # Whether this build was successful. Also see +state+ for a more detailed description.
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
  def execute!(begin_time=Time.now.utc)
    raise "Already executed" if exitstatus
    self.state = Executing.new
    self.begin_time = begin_time
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
    self.end_time = Time.now.utc
    determine_state
    File.open(revision.project.stdout_file) do |io| 
      self.stdout_id = connection.insert("INSERT INTO build_logs (data) VALUES('#{connection.quote_string(io.read)}')")
    end
    File.open(revision.project.stderr_file) do |io| 
      self.stderr_id = connection.insert("INSERT INTO build_logs (data) VALUES('#{connection.quote_string(io.read)}')")
    end

    save
    
    project.build_complete(self)
    
    self.exitstatus
  end
  
  # The description of the state
  def state_description
    state ? state.description : "Unknown"
  end
  
  # Number of seconds since the build ended, or nil if it hasn't ended yet
  def seconds_since_end
    end_time ? (Time.now.utc - end_time).to_i : nil
  end

  # :nodoc:
  def determine_state
    prev = previous
    prev_state = prev ? (prev.state ? prev.state : Successful.new) : Successful.new
    self.state = prev_state.send(successful? ? :succeed : :fail)
  end

  def icon
    if(successful?)
      "green-32.gif"
    else
      "red-32.gif"
    end
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

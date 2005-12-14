require 'file/tail'

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
  SCM_POLLED = "SCM_POLLED" unless defined? SCM_POLLED
  SCM_TRIGGERED = "SCM_TRIGGERED" unless defined? SCM_TRIGGERED
  MANUALLY_TRIGGERED = "MANUALLY_TRIGGERED" unless defined? MANUALLY_TRIGGERED
  SUCCESSFUL_DEPENDENCY = "SUCCESSFUL_DEPENDENCY" unless defined? SUCCESSFUL_DEPENDENCY

  belongs_to :revision
  belongs_to :build_executor
  belongs_to :triggering_build, :class_name => "Build"
  has_many :artifacts, :dependent => true
  serialize :env
  serialize :state

  #validates_inclusion_of :reason, :in => [SCM_POLLED, SCM_TRIGGERED, MANUALLY_TRIGGERED, SUCCESSFUL_DEPENDENCY]

  def before_create
    self.create_time ||= Time.now.utc
    self.state = Requested.new
  end
  
  def state=(state)
    write_attribute("state", state)
    unless new_record?
      save
      project.build_state_changed(self) if project
    end
  end

  def stdout_file
    log_file("stdout")
  end

  def stderr_file
    log_file("stderr")
  end
  
  def log_dir
    log_dir = "#{revision.basedir}/builds/#{id}"
    FileUtils.mkdir_p log_dir unless File.exist? log_dir
    log_dir
  end
  
  def log_file(name)
    raise 'id not set' unless id
    "#{log_dir}/#{name}.log"
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
  
  # The estimated duration of this build, or nil if it cannot be determined.
  def estimated_duration
    lb = project.builds(:exitstatus => 0)[0]
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
    exited_ok = exitstatus == 0

    bad_stdout = matches?(tail(stdout_file), project.stdout_failure_patterns)
    bad_stderr = matches?(tail(stderr_file), project.stderr_failure_patterns)

    # BLAH
#    ok_stdout = matches?(tail(stdout_file), project.stdout_success_patterns)
#    ok_stderr = matches?(tail(stderr_file), project.stderr_success_patterns)
    
    exited_ok && !bad_stderr && !bad_stdout
  end
  
  def matches?(string, regexps)
    regexps.each {|regexp| return true if string =~ regexp}
    false
  end
  
  # Whether this build has completed or not.
  def completed?
    !exitstatus.nil?
  end

  # Executes this build
  def execute!
    build_executor.execute(self)
  end
  
  # Number of seconds since the build ended, or nil if it hasn't ended yet
  def seconds_since_end
    end_time ? (Time.now.utc - end_time).to_i : nil
  end

  # The previous build for the associated project. May be within the same revision or not.
  def previous
    project.builds(:before => create_time)[0]
  end

  def determine_state #:nodoc:
    prev = previous
    prev_state = prev ? (prev.state ? prev.state : Successful.new) : Successful.new
    self.state = prev_state.send(successful? ? :succeed : :fail)
  end

  def tail(file, n=30)
    result = ""
    file = File::Tail::Logfile.new(file).rewind(n)
    file.return_if_eof = true
    file.tail{|line| result << line}
    result
  end

  class State
    def name
      @@name ||= self.class.name.demodulize.underscore
    end

    def verb
      "was"
    end
  end

  class Unfinished < State
    def fail
      Broken.new
    end
    def succeed
      Successful.new
    end
    def verb
      "is"
    end
  end
  
  class Requested < Unfinished
  end

  class SynchingWorkingCopy < Unfinished
  end

  class Executing < Unfinished
  end

  class Successful < State
    def succeed
      Successful.new
    end
    def fail
      Broken.new
    end
  end

  class Fixed < Successful
  end

  class Broken < State
    def succeed
      Fixed.new
    end
    def fail
      RepeatedlyBroken.new
    end
  end

  class RepeatedlyBroken < Broken
  end 
  
  STATES = [Requested.new, SynchingWorkingCopy.new, Executing.new, Successful.new, Fixed.new, Broken.new, RepeatedlyBroken.new] unless defined? STATES
  COMPLETE_STATES = [Successful.new, Fixed.new, Broken.new, RepeatedlyBroken.new] unless defined? COMPLETE_STATES

end

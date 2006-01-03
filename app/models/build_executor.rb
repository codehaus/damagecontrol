# A build executor is responsible for executing a build
class BuildExecutor < ActiveRecord::Base
  has_many :builds
  
  # The sole master instance
  def self.master_instance
    begin
      @@local ||= find(1) 
    rescue ActiveRecord::RecordNotFound => e
      @@local = create(:id => 1, :is_master => true, :description => "Master build executor")
    end
  end
  
  # Requests a build. All this does is to store a new build row in the database.
  # It will not be executed until +execute+ is called.
  def request_build_for(revision, reason, triggering_build)
    build_number = revision.project.build_count + 1
    build = nil
    transaction do
      build = revision.builds.create(:number => build_number, :reason => reason, :triggering_build => triggering_build)
      self.builds << build
    end
    build
  end

  # Executes a build and persists results.
  # The following steps occur when calling this method:
  #
  # 1) The working copy is updated to this build's revision
  # 2) The build's build_executor executes the build
  #
  def execute(build)
    raise "Already executed" if build.exitstatus

    # Make sure the working copy is in sync, and possibly reload settings from
    # a checked-in damagecotrol.yml
    build.state = ::Build::SynchingWorkingCopy.new
    build.save
    
    build.revision.sync_working_copy!(build.stdout_file, build.stderr_file)
    build.command = build.revision.project.build_command
    build.env = {}.merge(ENV).merge(build.revision.build_environment)
    if(is_master)
      execute_local(build)
    end
  end

private

  def execute_local(build)
    begin
      build.state = ::Build::Executing.new
      build.begin_time = Time.now.utc
      build.save
      exitstatus = RSCM::CommandLine.execute(build.command,
        :dir => build.revision.project.build_dir,
        :stdout => build.stdout_file, 
        :stderr => build.stderr_file, 
        :env => build.env
      )
    rescue RSCM::CommandLine::ExecutionError => e
      exitstatus = e.exitstatus
    ensure
      build.exitstatus = exitstatus
      build.end_time = Time.now.utc
      build.determine_state
      build.project.build_complete(build)
      logger.info "Build of #{build.project.name}'s revision #{build.revision.identifier} complete. Exitstatus: #{build.exitstatus}" if logger
    end
    nil
  end

end

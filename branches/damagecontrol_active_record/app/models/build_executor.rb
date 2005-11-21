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
    build = revision.builds.create(:number => build_number, :reason => reason, :triggering_build => triggering_build)
    self.builds << build
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
    
    needs_zip = is_master
    build.revision.sync_working_copy!(needs_zip)
    build.command = build.revision.project.build_command
    build.env = build.revision.build_environment
    if(is_master)
      execute_local(build)
    end
  end

private

  def execute_local(build)
    Dir.chdir(build.revision.project.build_dir) do
      begin
        redirected_cmd = "#{build.command} > #{build.stdout_file} 2> #{build.stderr_file}"
        logger.info "Executing build for #{build.revision.project.name}'s revision #{build.revision.identifier}: #{redirected_cmd}" if logger
        build.env.each{|k,v| ENV[k]=v}
        build.state = ::Build::Executing.new
        build.begin_time = Time.now.utc
        build.save

        `#{redirected_cmd}`
      rescue Errno::ENOENT => e
        File.open(build.stderr_file, "w") {|io| io.write(e.message)}
      end
    end
    
    build.exitstatus = $?.exitstatus
    build.end_time = Time.now.utc
    build.determine_state

    build.project.build_complete(build)
    logger.info "Build of #{build.project.name}'s revision #{build.revision.identifier} complete. Exitstatus: #{build.exitstatus}" if logger

    nil
  end

end

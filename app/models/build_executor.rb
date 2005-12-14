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
    exitstatus = -1
    commands = build.command.split("&&").collect{|c| c.strip}
    Dir.chdir(build.revision.project.build_dir) do
      i = -1
      redirected_cmd = commands.collect do |c| 
        i+=1
        "echo \"damagecontrol> #{commands[i]}\" >> #{build.stdout_file} && " +
        "echo \"damagecontrol> #{commands[i]}\" >> #{build.stderr_file} && " +
        "#{c} >> #{build.stdout_file} 2>> #{build.stderr_file}"
      end.join(" && ")

      build.env.each{|k,v| ENV[k]=v}
      build.state = ::Build::Executing.new
      build.begin_time = Time.now.utc
      build.save

      begin
        # Redirect each subcommand (separated with &&) to a separate file. We'll concatenate them at the end.
        `#{redirected_cmd}`
        exitstatus = $?.exitstatus
      rescue Errno::ENOENT => e
        File.open(build.stderr_file, "a") {|io| io.write(e.message)}
      end
    end
    
    build.exitstatus = exitstatus
    build.end_time = Time.now.utc
    build.determine_state

    build.project.build_complete(build)
    logger.info "Build of #{build.project.name}'s revision #{build.revision.identifier} complete. Exitstatus: #{build.exitstatus}" if logger

    nil
  end

end

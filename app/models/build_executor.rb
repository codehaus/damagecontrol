class BuildExecutor < ActiveRecord::Base
  has_many :builds
  
  # The sole master instance
  def self.master_instance
    begin
      @local ||= find(1) 
    rescue ActiveRecord::RecordNotFound => e
      @local = create(:id => 1, :is_master => true, :description => "Master build executor")
    end
  end
  
  # Requests a build.
  def request_build_for(revision, reason, triggering_build)
    build_number = revision.project.build_count + 1
    build = revision.builds.create(:number => build_number, :reason => reason, :triggering_build => triggering_build)
    self.builds << build
    build
  end

  def execute(build)
    execute_local(build)
  end

private
  
  def execute_local(build)
    build.state = ::Build::Executing.new
    build.begin_time = Time.now.utc
    build.save

    Dir.chdir(build.revision.project.build_dir) do
      begin
        FileUtils.mkdir_p(File.dirname(build.stdout_file)) unless File.exist?(File.dirname(build.stdout_file))
        redirected_cmd = "#{build.command} > #{build.stdout_file} 2> #{build.stderr_file}"
        logger.info "Executing build for #{build.revision.project.name}'s revision #{build.revision.identifier}: #{redirected_cmd}" if logger
        build.env.each{|k,v| ENV[k]=v}
        build.project.build_executing(build)

        `#{redirected_cmd}`
      rescue Errno::ENOENT => e
        File.open(build.stderr_file, "w") {|io| io.write(e.message)}
      end
    end
    
    build.exitstatus = $?.exitstatus
    build.end_time = Time.now.utc
    build.determine_state

    build.save
    
    build.project.build_complete(build)
    logger.info "Build of #{build.project.name}'s revision #{build.revision.identifier} complete. Exitstatus: #{build.exitstatus}" if logger

    nil
  end

end

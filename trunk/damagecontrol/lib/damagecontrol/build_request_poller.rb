require 'fileutils'
require 'yaml'
require 'damagecontrol/project'

module DamageControl
  # Polls build requests from file and enqueues them in a build queue
  # The build requests are usually stored on file by the webapp.
  class BuildRequestPoller
    def initialize(basedir, build_queue)
      @basedir = basedir
      @build_queue = build_queue
    end
    
    def poll
      Log.info("Polling build requests")
      Dir["#{@basedir}/build_requests/*"].each do |request_file|
        request = YAML::load_file(request_file)
        project_name = request[:project_name]
        project = load_project(project_name)
        revision = project.revision(request[:revision_identifier])
        reason = request[:reason]
        Log.info("Enqueuing build request for #{project_name}:#{revision.identifier}")
        @build_queue.enqueue(revision, reason)
        FileUtils.rm(request_file)
      end
    end

    def load_project(project_name)
      Project.load("#{@basedir}/projects/#{project_name}/project.yaml")
    end
  end
end
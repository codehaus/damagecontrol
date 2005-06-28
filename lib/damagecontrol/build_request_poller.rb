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
      begin
        requests_dir = "#{@basedir}/build_requests"
        Log.info("Polling build requests from #{requests_dir}")
        Dir["#{requests_dir}/*"].each do |request_file|
          Log.info("Handling persisted request #{request_file}")
          request = YAML::load_file(request_file)
          project_name = request[:project_name]
          project = load_project(project_name)
          revision = project.revision(request[:revision_identifier].to_s.to_identifier)
          if(revision)
            reason = request[:reason]
            Log.info("Enqueuing build request for #{project_name}:#{revision.identifier}")
            @build_queue.enqueue(revision, reason)
          else
            Log.info("Request referred to nonexistant revision: #{request.inspect}")
          end
          FileUtils.rm(request_file)
        end
      rescue => e
        # probably a bogus request
        Log.error e.message
        Log.error e.backtrace.join("\n")
      end
    end

    def load_project(project_name)
      Project.load("#{@basedir}/projects/#{project_name}/project.yaml")
    end
  end
end
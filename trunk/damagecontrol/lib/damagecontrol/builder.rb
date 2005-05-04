module DamageControl
  # A builder builds a revision
  class Builder
  
    def initialize(build_queue, projects_dir, project_finder=Project)
      @build_queue, @projects_dir, @project_finder = build_queue, projects_dir, project_finder
    end
    
    # Builds next build request in queue
    def build_next
      request = @build_queue.pop(self)
      revision = request.revision
      project = revision.project
      latest_revision = project.latest_revision
      build = revision.build!(request.reasons)
      if(build.successful? && revision == latest_revision)
        request_build_for_dependant_projects(project)
      end
      @build_queue.delete(request)
    end

  private
  
    def request_build_for_dependant_projects(project)
      @project_finder.find_all(@projects_dir).each do |p|
        if(p.depends_directly_on?(project))
          @build_queue.enqueue(p.latest_revision, "Successful build of dependency #{project.name}")
        end
      end
    end
  
  end
end
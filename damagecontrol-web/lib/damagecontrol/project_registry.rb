module DamageControl
  class ProjectRegistry
    def initialize
      @projects = []
    end
    
    def add(project)
      @projects << project
    end
    
    def candidate_dependencies(project)
      projects = @projects.dup
      projects.delete(project)
      projects
    end
  end
end

require 'webrick'
require 'pebbles/MVCServlet'

module DamageControl
  class AbstractAdminServlet < Pebbles::MVCServlet
    def initialize(type, build_scheduler, build_history_repository)
      @type = type
      @build_scheduler = build_scheduler
      @build_history_repository = build_history_repository
    end
    
  protected
    
    def title
      ""
    end
    
    def tasks
      {}
    end
    
    def ritemesh_template
      "decorators/default.erb"
    end
    
    def assert_private
      raise "not privileged" if @type != :private
    end
  
    def private?
      @type == :private
    end
    
    # last_completed_or_current must be :last_completed_build or :current_build
    def get_status_image(last_or_current, project_name)
      color = "grey"
      pulse = ""
      build = @build_history_repository.send(last_or_current, project_name)
      if(!build.nil?)
        color = if build.successful? then "green" else "red" end
        pulse = "-pulse" if @build_scheduler.project_building?(project_name) && last_or_current == :current_build
      end
      image = "images/#{color}#{pulse}-32.gif"
    end

  private
    
    attr_reader :build_history_repository

  end
end

require 'pebbles/MVCServlet'

module DamageControl
  class StatusImageServlet < Pebbles::SimpleServlet
  
    def initialize(build_history_repository, build_scheduler)
      @build_history_repository = build_history_repository
      @build_scheduler = build_scheduler
    end
    
    def service(req, res)
      super(req, res)
      project_name = req.query['project_name'] || required_parameter('project_name')
      path = status_image(project_name)
      st = File::stat(status_image(project_name))
      res['content-length'] = st.size
      res.body = open(path, "rb")
    end
  
    protected
    
    def content_type
      "image/gif"
    end
    
    def last_or_current
      raise "should override"
    end
    
    private
    
    # last_completed_or_current must be :last_completed_build or :current_build
    def status_image(project_name)
      color = "grey"
      pulse = ""
      build = @build_history_repository.send(last_or_current, project_name)
      if(!build.nil?)
        color = if build.successful? then "green" else "red" end
        pulse = "-pulse" if @build_scheduler.project_building?(project_name) && last_or_current == :current_build
      end
      image = "#{imagedir}/#{color}#{pulse}-32.gif"
    end
    
    def imagedir
      "#{File.dirname(__FILE__)}/images"
    end
    
  end
  
  class CurrentStatusImageServlet < StatusImageServlet
    protected
    
    def last_or_current
      :current_build
    end
  end

  class LastCompletedImageServlet < StatusImageServlet
    protected
    
    def last_or_current
      :last_completed_build
    end
  end
end
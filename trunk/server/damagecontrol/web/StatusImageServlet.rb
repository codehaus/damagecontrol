require 'pebbles/MVCServlet'

module DamageControl
  class StatusImageServlet < Pebbles::SimpleServlet
  
    def initialize(build_history_repository, build_scheduler)
      @build_history_repository = build_history_repository
      @build_scheduler = build_scheduler
      @image_dir = File.expand_path("#{File.dirname(__FILE__)}/images")
    end
    
    def service(req, res)
      super(req, res)
      project_name = req.path_info || req.query['project_name'] || required_parameter('project_name')
      path = status_image(project_name)
      st = File::stat(path)
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
      build = find_build(project_name)
      if(build && build.completed?)
        color = if build.successful? then "green" else "red" end
        pulse = "-pulse" if @build_scheduler.project_building?(project_name)
      end
      image = "#{@image_dir}/#{color}#{pulse}-32.gif"
    end
    
  end
  
  class CurrentStatusImageServlet < StatusImageServlet
    protected
    
    def find_build(project_name)
      @build_history_repository.current_build(project_name)
    end
  end

  class LastCompletedImageServlet < StatusImageServlet
    protected
    
    def find_build(project_name)
      @build_history_repository.last_completed_build(project_name)
    end
  end

  class TimestampImageServlet < StatusImageServlet
    protected
    
    def find_build(project_name)
      dc_creation_time = request.query["dc_creation_time"]
      @build_history_repository.lookup(project_name, dc_creation_time)
    end
  end
end
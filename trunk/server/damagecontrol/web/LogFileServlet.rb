require 'pebbles/MVCServlet'

module DamageControl
  class LogFileServlet < Pebbles::SimpleServlet
  
    def initialize(project_directories)
      @project_directories = project_directories
    end
    
    def service(req, res)
      super(req, res)
      project_name = req.query['project_name'] || required_parameter('project_name')
      dc_creation_time = req.query['dc_creation_time'] || required_parameter('dc_creation_time')
      path = @project_directories.log_file(project_name, dc_creation_time)
      st = File::stat(path)
      res['content-length'] = st.size
      res['last-modified'] = st.mtime.httpdate
      res.body = open(path, "r")
    end
  
    protected
    
    def content_type
      "text/plain"
    end
    
    def last_or_current
      raise "should override"
    end
    
  end
end
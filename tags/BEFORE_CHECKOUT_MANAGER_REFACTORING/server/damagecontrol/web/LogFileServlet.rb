require 'pebbles/MVCServlet'

module DamageControl
  class LogFileServlet < Pebbles::SimpleServlet
  
    def initialize(project_directories)
      @project_directories = project_directories
    end
    
    def service(req, res)
      super(req, res)
      project_name = req.query['project_name'] || required_parameter('project_name')
      timestamp = req.query['timestamp'] || required_parameter('timestamp')
      path = @project_directories.log_file(project_name, timestamp)
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
require 'damagecontrol/web/AbstractAdminServlet'

module DamageControl
  class LogFileServlet < AbstractAdminServlet
  
    def service(req, res)
      super(req, res)
      path = @build_history_repository.stdout_file(project_name, dc_creation_time)
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
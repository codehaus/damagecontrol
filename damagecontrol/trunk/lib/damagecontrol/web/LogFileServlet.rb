require 'damagecontrol/web/AbstractAdminServlet'
require 'pebbles/TimeUtils.rb'

module DamageControl
  class LogFileServlet < AbstractAdminServlet
  
    def service(req, res)
      super(req, res)
      
      project_name = req.path_info.split("/")[1]
      dc_creation_time = Time.parse_ymdHMS req.path_info.split("/")[3]
      
      if (req.path_info.split("/")[4] == "stdout.log")
        path = @build_history_repository.stdout_file(project_name, dc_creation_time)
      else
        path = @build_history_repository.stderr_file(project_name, dc_creation_time)
      end
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
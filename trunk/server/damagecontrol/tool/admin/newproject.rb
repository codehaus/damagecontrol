require 'damagecontrol/tool/Task'

class NewProjectTask < ConfigTask
  commandline_option :projectname
  
  def run
    server.project_config_repository.new_project(projectname)
    
    # sanity check
    server.project_config_repository.project_config(projectname)
  end
end

NewProjectTask.new.run
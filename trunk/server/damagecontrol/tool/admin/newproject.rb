require 'damagecontrol/tool/Task'

class NewProjectTask < ConfigTask
  commandline_option :projectname
  
  def run
    @project_config_repository.new_project(projectname)
    
    # sanity check
    @project_config_repository.project_config(projectname)
  end
end

NewProjectTask.new.run
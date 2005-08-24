class Project < ActiveRecord::Base
  
  def import_from_meta_project(scm_web_url)
    meta_project = MetaProject::ProjectAnalyzer.project_from_scm_web(scm_web_url)
    if(meta_project)
      self.home_page = meta_project.home_page_uri
      self.tracker   = meta_project.tracker
      self.scm_web   = meta_project.scm_web
      self.scm       = meta_project.scm

      self.build_command = meta_project.build_command
      self.publishers    = meta_project.publisher
      
      save
    end
  end
end

# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.

require 'damagecontrol/project'
require 'damagecontrol/build'
require 'damagecontrol/tracker'
require 'damagecontrol/scm_web'
require 'damagecontrol/publisher/base'
require 'rscm_ext'
require 'rails_ext'

class ApplicationController < ActionController::Base

  layout 'default'

  def initialize
    @sidebar_links = [
      {
        :controller => "project", 
        :action     => "new", 
        :image      => "/images/24x24/box_new.png",
        :name       => "New project"
      }
    ]
    @controller = self
  end

  # Loads the project specified by the +id+ parameter and places it into the @project variable  
  def load_project
    project_name = @params["id"]
    @project = DamageControl::Project.load(project_name)
  end

protected

  # Sets the links to display in the sidebar. Override this method in other controllers
  # To change what to display.
  def set_sidebar_links

  end
  
end
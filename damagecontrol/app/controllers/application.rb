# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.

require 'rscm_ext'
require 'rails_ext'
require 'damagecontrol/project'
require 'damagecontrol/build'
require 'damagecontrol/tracker'
require 'damagecontrol/scm_web'
# TODO: find a way so we don't have to explicitly load these
require 'damagecontrol/publisher/email'
require 'damagecontrol/publisher/irc'
require 'damagecontrol/publisher/growl'

class ApplicationController < ActionController::Base

  layout 'rscm'

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

  def breadcrumbs
    subpaths = @request.path.split(/\//)
#    subpaths.collect { |p| link_to_unless_current(p) }.links.join(" ")
  end

protected

  # Sets the links to display in the sidebar. Override this method in other controllers
  # To change what to display.
  def set_sidebar_links

  end
  
end

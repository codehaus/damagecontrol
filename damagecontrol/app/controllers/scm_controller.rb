class ScmController < ApplicationController

  # Creates the SCM repo
  def create
    load_project
    @project.scm.create_central
    redirect_to :controller => "project", :action => "view", :id => @project.name
  end

  def delete_working_copy
    load_project
    @project.delete_working_copy
    redirect_to :controller => "project", :action => "view", :id => @project.name
  end

end

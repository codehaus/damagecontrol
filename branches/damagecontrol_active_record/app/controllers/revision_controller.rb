class RevisionController < ApplicationController

  layout "application", :except => :list

  def list
    @project = Project.find(@params[:id])
    @revisions = @project.revisions
    
    load_builds_for_sparkline(@project)
  end
  
  def show
    @revision = Revision.find(@params[:id])

    # first rendering of revision list
    @project = @revision.project
    @revisions = @revision.project.revisions
    @template_for_left_column = "revision/list"
    
    @revision_message = @revision.message

    load_builds_for_sparkline(@project)
  end

  # Requests a build. Nothing is rendered.
  def build
    @revision = Revision.find(@params[:id])
    @revision.request_build(Build::MANUALLY_TRIGGERED)
    render :text => "Build requested"
  end
  
end

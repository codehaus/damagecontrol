class RevisionController < ApplicationController
  layout "application"

  def list
    project = Project.find(@params[:id])
    @revisions = project.revisions
  end
  
  def show
    @revision = Revision.find(@params[:id])

    @revisions = @revision.project.revisions
    @template_for_left_column = "revision/list"
  end

end

class RevisionController < ApplicationController
  layout "application", :except => :list

  def list
    @project = Project.find(@params[:id])
    @revisions = @project.revisions
  end
  
  def show
    @revision = Revision.find(@params[:id])

    # first rendering of revision list
    @project = @revision.project
    @revisions = @revision.project.revisions
    @revision_list_refresh = true
    @template_for_left_column = "revision/list"
  end

end

class RevisionController < ApplicationController
  def list
    project = Project.find(@params[:id])
    @revisions = project.revisions
  end
end

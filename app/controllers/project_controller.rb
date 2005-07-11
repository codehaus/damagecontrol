class ProjectController < ApplicationController
  layout "default"

  def index
    @projects = Project.find(:all)
  end

  def new
    @project = Project.new
    @action = "create"
    render :action => "edit"
  end

  def create
    project = Project.create(@params[:project])
    redirect_to :action => "edit", :id => project.id
  end
  
  def update
    project = Project.create(@params[:project])
    redirect_to :action => "edit", :id => project.id
  end

  def edit
    @project = Project.find(@params[:id])
    @action = "update"
    render :action => "edit"
  end

  def view
    @project = Project.find(@params[:id])
    render :action => "edit"
  end

end

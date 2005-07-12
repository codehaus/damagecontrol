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
    project_attrs = @params[:project].dup
    project_attrs[:scm] = extract(:scm)

    project = Project.find(@params[:id])    
    project.update_attributes(project_attrs)
    
    redirect_to :action => "edit", :id => project.id
  end

  def edit
    @project = Project.find(@params[:id])
    @action = "update"
    define_scms(@project)
    render :action => "edit"
  end

  def view
    @project = Project.find(@params[:id])
    render :action => "edit"
  end
  
private
  
  def define_scms(project)
    scms = RSCM::Base.classes.collect{|cls| cls.new}
    @scms = scms.collect{|scm| scm.class == project.scm.class ? project.scm : scm}
  end

end

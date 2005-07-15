class ProjectController < ApplicationController
  layout "application", :except => :dashboard
  
  def index
  end

  def new
    @project = Project.new
    define_scms(@project)
    @submit_action = "create"
    @submit_text = "Create project"
    render :action => "edit"
  end

  def edit
    @project = Project.find(@params[:id])
    define_scms(@project)
    @submit_action = "update"
    @submit_text = "Update project"
    render :action => "edit"
  end

  def create
    update_or_save(Project.create(@params[:project]))
  end

  def update
    update_or_save(Project.find(@params[:id]))
  end
  
  def dashboard
    render :partial => "project/dashboard"
  end
  
private
  
  def update_or_save(project)
    project_attrs = @params[:project].dup
    project_attrs[:scm] = extract(:scm)

    project.update_attributes(project_attrs)    
    redirect_to :action => "edit", :id => project.id
  end

  def define_scms(project)
    scms = RSCM::Base.classes.collect{|cls| cls.new}
    @scms = scms.collect{|scm| scm.class == project.scm.class ? project.scm : scm}
  end

end

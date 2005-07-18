class ProjectController < ApplicationController
  layout "application", :except => :list
  
  def index
  end

  def new
    @project = Project.new
    @project.scm = RSCM::Cvs.new
    define_plugins

    @submit_action = "create"
    @submit_text = "Create project"
    render :action => "settings"
  end

  def edit
    @project = Project.find(@params[:id])
    define_plugins

    @submit_action = "update"
    @submit_text = "Update project"
    render :action => "settings"
  end

  def create
    update_or_save(Project.create(@params[:project]))
  end

  def update
    update_or_save(Project.find(@params[:id]))
  end
  
  def show
    @project = Project.find(@params[:id])
  end
  
  def list
  end
  
private
  
  def update_or_save(project)
    project_attrs = @params[:project].dup
    project_attrs[:scm] = extract(:scm)

    project.update_attributes(project_attrs)    
    redirect_to :action => "edit", :id => project.id
  end

  def define_plugins
    define_scms
    @publishers = DamageControl::Publisher::Base.classes.collect{|cls| cls.new}
    @trackers = DamageControl::Tracker::Base.classes.collect{|cls| cls.new}
    @scm_webs = DamageControl::ScmWeb::Base.classes.collect{|cls| cls.new}
    
    @rows = [[@project], @scms, @publishers, @trackers, @scm_webs]
  end

  # Instantiates all known SCMs. The project's persisted scm
  # will also be among these, and will have the persisted attribute values.
  def define_scms
    scms = RSCM::Base.classes.collect{|cls| cls.new}
    @scms = scms.collect{|scm| scm.class == @project.scm.class ? @project.scm : scm}
  end

end

class ProjectController < ApplicationController

  # TODO: check if the various SCMs are installed and disable them with a warning if not.
  # Each SCM class should have an available? method

  before_filter do
    @navigation_name = "revisions_list"
  end

  def index
    @projects = Project.find(:all)
    @title = "DamageControl Dashboard"
  end

  def new
    @project = Project.new
    
    @title = "New DamageControl Project"
    @new_project = true
    view(true)
  end

  def create
    project = Project.create(@params['project'])
    redirect_to(:action => "edit", :id => project.id)
  end

  def edit
    view(true)
  end

  def view(edit=false)
    project = Project.find(@params[:id])
    define_connectors
    @edit = edit
    render_action("view")
  end

private

  def define_connectors
    define_scms
    define_trackers
  end

  def define_scms
    @scms = RSCM::AbstractSCM.classes.collect {|cls| cls.new}
    first_scm = @scms[0]
    def first_scm.selected?
      true
    end
  end
  
  def define_trackers
    @trackers = DamageControl::Tracker::Base.classes.collect {|cls| cls.new}
    first_tracker = @trackers[0]
    def first_tracker.selected?
      true
    end
  end

end

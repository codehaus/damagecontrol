class ProjectController < ApplicationController
  include MetaProject::ProjectAnalyzer

  layout "application", :except => :list
  before_filter :random_tip
  
  def index
  end

  def new
    @project = Project.new
    @project.publishers = []

    define_plugin_rows

    @submit_action = "create"
    @submit_text = "Create project"
    tip("importing")
    render :action => "settings"
  end

  def edit    
    find
    
    define_plugin_rows

    @submit_action = "update"
    @submit_text = "Update project"
    render :action => "settings"
  end

  def create
    project = Project.create(@params[:project])
    project.start_time = 2.weeks.ago
    import_or_update_or_save(project)
  end

  def update
    update_or_save(find)
  end
  
  def destroy
    project = find
    project.destroy
    flash["notice"] = "Successfully deleted #{project.name}"
    redirect_to :action => "index"
  end
  
  def show
    find
  end
  
  # This should only be called via AJAX to display the right column.
  def list
  end
  
  def rss
    find
    render :text => @project.rss(self)
  end
  
  def revisions_rss
    find
    render :text => @project.revisions_rss(self)
  end

  def builds_rss
    find
    render :text => @project.builds_rss(self)
  end

private

  def find
    @project = Project.find(@params[:id])
  end
  
  def import_or_update_or_save(project)
    import_settings = @params[:import]
    if(import_settings[:scm_web_url] && import_settings[:scm_web_url].strip != "")
      import(project, import_settings)
    else
      update_or_save(project)
    end
  end
  
  def import(project, import_settings)
    import_from_meta_project(
      project, 
      import_settings[:scm_web_url],
      import_settings
    )

    flash["notice"] = "Successfully imported settings for #{project.name}."
    redirect_to :action => "edit", :id => project.id
  end
  
  def update_or_save(project)
    project.scm        = deserialize_to_array(@params[:scm]).find{|scm| scm.enabled}
    project.tracker    = deserialize_to_array(@params[:tracker]).find{|tracker| tracker.enabled}
    project.publishers = deserialize_to_array(@params[:publisher])
    project.scm_web    = MetaProject::ScmWeb.new

    project.scm_web.overview_spec = @params[:scm_web][:overview_spec]
    project.scm_web.history_spec  = @params[:scm_web][:history_spec]
    project.scm_web.raw_spec      = @params[:scm_web][:raw_spec]
    project.scm_web.html_spec     = @params[:scm_web][:html_spec]
    project.scm_web.diff_spec     = @params[:scm_web][:diff_spec]

    project.update_attributes(@params[:project])

    redirect_to :action => "edit", :id => project.id
  end

  def define_plugin_rows
    # Workaround for AR bug
    @project.publishers = YAML::load(@project.publishers) if @project.publishers.class == String

    top_row = [@project, @project.scm_web, DamageControl::Importer::Import.new]
    @rows = [top_row, scms, publishers, trackers]
  end

  # Instantiates all known SCMs. The project's persisted scm
  # will also be among these, and will have the persisted attribute values.
  def scms
    RSCM::Base.classes.collect{|cls| cls.new}.collect do |scm|
      scm.class == @project.scm.class ? @project.scm : scm
    end.sort
  end

  def publishers
    DamageControl::Publisher::Base.classes.collect{|cls| cls.new}.collect do |publisher|
      already = @project.publishers.find do |p| 
        p.class.name == publisher.class.name
      end
      already ? already : publisher
    end.sort
  end

  def trackers
    MetaProject::Tracker::Base.classes.collect{|cls| cls.new}.collect do |tracker|
      tracker.class == @project.tracker.class ? @project.tracker : tracker
    end.sort
  end

end

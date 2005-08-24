class ProjectController < ApplicationController
  
  layout "application", :except => :list
  
  def index
  end

  def new
    @project = Project.new
    @project.publishers = []

    define_plugin_rows

    @submit_action = "create"
    @submit_text = "Create project"
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
    update_or_save(Project.create(@params[:project]))
  end

  def update
    update_or_save(find)
  end
  
  def show
    find
  end
  
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

  # TODO: fix me
  def import_ruby_forgeX
    project = import_ruby_forge_project(@params[:project_name])
    redirect_after_import(project, "RubyForge")
  end

  # TODO: fix me
  def import_tracX
    project = import_trac_project(@params[:project_name], @params[:browse_uri], @params[:svnroot_uri], @params[:svn_path])
    redirect_after_import(project, "Trac")
  end

private

  def redirect_after_import(project, source)
    flash["notice"] = "Successfully imported settings for #{project.name} from #{source}."
    redirect_to :action => "edit", :id => project.id
  end

  def find
    @project = Project.find(@params[:id])
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

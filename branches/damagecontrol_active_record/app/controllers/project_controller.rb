class ProjectController < ApplicationController
  include MetaProject::ProjectAnalyzer

  layout "application", :except => [:list, :jnlp, :rest_list]
  before_filter :define_feeds
  
  def index
  end

  def new
    @project = Project.new(:name => "Project #{@projects.length}")
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
    @submit_text = "Update #{@project.name}"
    render :action => "settings"
  end

  def show_import
    find
  end
  
  def export
    render :text => "<pre>#{find.export_to_hash.to_yaml}</pre>"
  end
  
  def import
    project = @params[:id] ? find : Project.new
    import_settings = @params[:import]

    import_from_meta_project(
      project, 
      import_settings[:scm_web_url],
      import_settings
    )

    # Set up some default publishers
    if(DamageControl::Platform.family == 'powerpc-darwin')
      project.add_growl
    end
    if(DamageControl::Platform.family == 'powerpc-darwin' || family == 'win32')
      project.add_sound
    end

    project.save
    flash["notice"] = "Successfully imported settings for #{project.name}."
    flash["notice"] << "<br/>I guessed that the build command is '#{project.build_command}'. Correct me if I'm wrong." if project.build_command
    redirect_to :action => "edit", :id => project.id
  end

  def create
    project = Project.create(@params[:project])
    populate_from_hash(project, @params)
    project.save
    redirect_to :action => "edit", :id => project.id
  end

  def update
    project = find
    populate_from_hash(project, @params)
    project.save
    redirect_to :action => "edit", :id => project.id
  end
  
  def test_publisher
    project = Project.new(@params[:project])
    populate_from_hash(project, @params)

    publisher_class_name = @params[:publisher_class_name]
    publisher = project.publishers.find{|p| p.class.name == publisher_class_name}
    
    build = Build.new(:state => Build::Successful.new)
    
    # TODO: render nothing and figure text with javascript on client (yellow appear effect)
    begin
      publisher.publish_maybe(build)
      render :text => "Tested #{publisher.visual_name}"
    rescue
      render :text => "Failed to test"
    end
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
  
  def timeline
    @revisions = @project.revisions
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
  
  # Java WebStart
  def jnlp
    response.headers["Content-Type"] = "application/x-java-jnlp-file"
  end
  
  #### REST API ####
  
  def rest_list
  end
  
protected

  def define_feeds
    if(find)
      feeds << Struct::Feed.new(:rss, {:controller => "project", :action => "rss", :id => @project.id}, "#{@project.name} revisions and builds")
    end
  end
  
  def page_title
    find
    @page_title = @project ? "DamageControl: #{@project.name}" : "DamageControl"
  end

  def tip_category
    :project_settings
  end

private

  def page_title
    if(@params[:id])
      @project = Project.find(@params[:id])
      @page_title = "#{@project.name}"
    else
      @page_title = "Projects"
    end
  end

  def find
    @project ||= Project.find(@params[:id]) if @params[:id]
  end
  
  def populate_from_hash(project, params)
    # move 'up' the entries that are under :project.
    # the POSTed hash (@params) aren't exactly how we want things
    hash = params.dup
    hash.merge!(params[:project])
    project.populate_from_hash(hash)
  end
  
  def define_plugin_rows
    # Workaround for AR bug
    @project.publishers = YAML::load(@project.publishers) if @project.publishers.class == String

    top_row = [@project, @project.scm_web]
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

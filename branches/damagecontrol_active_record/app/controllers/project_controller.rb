class ProjectController < ApplicationController
  include MetaProject::ProjectAnalyzer
  verify :method => :post, :only => %w( import create update destroy test_publisher request_scm_poll)

  layout "application", :except => [:jnlp]
  before_filter :define_feeds
  
  def new
    @project = Project.new(:name => "Project #{@projects.length}")
    @project.publishers = []

    define_plugin_groups

    @submit_action = "create"
    @submit_text = "Create project"
    tip("importing")
    render :action => "settings"
  end

  def edit    
    find
    
    define_plugin_groups

    @submit_action = "update"
    @submit_text = "Update #{@project.name}"
    render :action => "settings"
  end
  
  def show_import
    find
  end
  
  def export
    response.headers["Content-Type"] = "text/plain"
    render :text => "#{find.export_to_hash.to_yaml}"
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
    if(DamageControl::RSCM::Platform.family == 'powerpc-darwin')
      project.add_growl
    end
    if(DamageControl::RSCM::Platform.family == 'powerpc-darwin' || DamageControl::RSCM::Platform.family == 'win32')
      project.add_sound
    end

    project.save
    flash["notice"] = "Successfully imported settings for #{project.name}."
    flash["notice"] << "<br/>I guessed that the build command is '#{project.build_command}'. Correct me if I'm wrong." if project.build_command
    redirect_to :action => "edit", :id => project.id
  end

  def create
    project = Project.create(@params[:project])
    if(project.id)
      populate_from_hash(project, @params)
      project.save
    else
      notice "There is already a project named #{project.name}"
    end
    redirect_to :action => "edit", :id => project.id
  end

  def update
    project = find
    populate_from_hash(project, @params)
    project.save
    redirect_to :action => "edit", :id => project.id
  end
  
  # Tests a publisher with a dummy build object
  def test_publisher
    project = Project.new(@params[:project])
    populate_from_hash(project, @params)

    publisher_class_name = @params[:publisher_class_name]
    publisher = project.publishers.find{|p| p.class.name == publisher_class_name}
    
    build_state_class_name = @params[:build_state_class_name]
    build_state = eval(build_state_class_name).new

    dummy_revision = Revision.new
    dummy_revision.developer = "_why"
    dummy_revision.identifier = 1971
    dummy_revision.project = project

    build = Build.new(:state => build_state)
    build.revision = dummy_revision
    def build.reason_description
      "it's not a real build"
    end
    def build.stdout_file
      File.dirname(__FILE__) + '/test_stdout.log'
    end
    def build.stderr_file
      File.dirname(__FILE__) + '/test_stderr.log'
    end

    begin
      status = publisher.publish(build)
      render :text => (status.is_a?(String) && status.strip != "") ? status : "Tested #{publisher.class.name}"
    rescue => e
      trace = e.backtrace.join("\n")
      render :text => "Failed to test: #{e.message}<br/><pre>#{trace}</pre>"
    end
  end

  def destroy
    project = find
    project.destroy
    notice "Successfully deleted #{project.name}"
    redirect_to :action => "list"
  end
  
  def show
    find
  end
  
  # Requests the polling of the SCM. Intended to be used for projects with scm polling off
  # (triggering on) and can be called with 
  # curl http://localhost:3000/project/request_scm_poll/1?time=`date -u +%Y%m%d%H%M%S`
  def request_scm_poll
    @project.poll_requests.create
    render :text => "DamageControl received SCM poll request for #{@project.name}\n", :layout => false
  end

  def timeline
    @revisions = @project.revisions
  end

  def rss
    find
    render :text => @project.rss(self), :layout => false
  end
  
  def revisions_rss
    find
    render :text => @project.revisions_rss(self), :layout => false
  end

  def builds_rss
    find
    render :text => @project.builds_rss(self), :layout => false
  end
  
  def scm_stdout
    send_log(find.scm_log("stdout"))
  end

  def scm_stderr
    send_log(find.scm_log("stderr"))
  end

  # Java WebStart
  def jnlp
    response.headers["Content-Type"] = "application/x-java-jnlp-file"
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
    project.populate_from_hash(hash, self)
  end
  
  def define_plugin_groups
    # Workaround for AR bug
    @project.publishers = YAML::load(@project.publishers) if @project.publishers.class == String

    @plugin_groups = [[@project, @project.scm_web], scms, publishers, trackers]
  end

  # Instantiates all known SCMs. The project's persisted scm
  # will also be among these, and will have the persisted attribute values.
  def scms
    RSCM::Base.classes.collect{|cls| cls.new}.collect do |scm|
      scm.class == @project.scm.class ? @project.scm : scm
    end.sort{|a,b| a.class.name <=> b.class.name}
  end

  def publishers
    @project.publishers ||= []
    result = []
    DamageControl::Publisher::Base.classes.each do |cls|
      if(cls.supported?)
        publisher = cls.new
        already = @project.publishers.find do |p| 
          p.class.name == publisher.class.name
        end
        result << (already ? already : publisher)
      end
    end
    result.sort{|a,b| a.class.name <=> b.class.name}
  end

  def trackers
    MetaProject::Tracker::Base.classes.collect{|cls| cls.new}.collect do |tracker|
      tracker.class == @project.tracker.class ? @project.tracker : tracker
    end.sort{|a,b| a.class.name <=> b.class.name}
  end

end

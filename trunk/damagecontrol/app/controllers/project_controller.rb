require 'rscm'
require 'damagecontrol/project'
require 'damagecontrol/diff_parser'
require 'damagecontrol/diff_htmlizer'
require 'damagecontrol/publisher/base'

class ProjectController < ApplicationController

  # TODO: check if the various SCMs are installed and disable them with a warning if not.
  # Each SCM class should have an available? method

  before_filter do
    @navigation_name = "revisions_list"
  end

  def index
    @projects = DamageControl::Project.find_all("#{BASEDIR}/projects")
    @navigation_name = "null"
  end

  def new
    @project = DamageControl::Project.new
    @projects = DamageControl::Project.find_all("#{BASEDIR}/projects")

    @scms = RSCM::AbstractSCM.classes.collect {|cls| cls.new}
    first_scm = @scms[0]
    def first_scm.selected?
      true
    end
    
    @trackers = DamageControl::Tracker::Base.classes.collect {|cls| cls.new}
    first_tracker = @trackers[0]
    def first_tracker.selected?
      true
    end
    @edit = true
    @new_project = true
    render_action("view")
  end

  def view
    return render_text("No project specified") unless @params["id"]
    @edit = false
    @navigation_name = "revisions_list"
    @projects = DamageControl::Project.find_all("#{BASEDIR}/projects")
    load
  end

  def edit
    @edit = true
    load
    @navigation_name = "revisions_list"
    @projects = DamageControl::Project.find_all("#{BASEDIR}/projects")
    render_action("view")
  end
  
  def revisions_rss
    load
    send_file(@project.revisions_rss_file)
  end

  def save
    project = instantiate_from_hash(DamageControl::Project, @params[DamageControl::Project.name])
    project.scm = find_selected("scms")
    project.tracker = find_selected("trackers")
    project.publishers = instantiate_array_from_hashes(@params["publishers"])
    project.dir = "#{BASEDIR}/projects/#{project.name}"
    
    # TODO: this is quite clunky (loads all projects to add). Find a better way.
    project.clear_dependencies
    posted_dependencies = @params["dependencies"] || []
    posted_dependencies.each do |project_name|
      begin
        project.add_dependency(DamageControl::Project.load("#{BASEDIR}/projects/#{project_name}/project.yaml"))
      rescue => e
        # project might have been deleted or removed
        $stderr.puts("Failed to add dependency #{project.name} -> #{project_name}")
        raise e
      end
    end
    
    project.save

    redirect_to(:action => "view", :id => project.name)
  end
  
  def revision
    load
    @navigation_name = "revisions_list"
    revision_identifier = @params["revision"]
    @revision = @project.revision(revision_identifier.to_identifier)
  end

  def latest_revision_json
    load
    render_text @project.latest_revision.to_json
  end
  
protected

  def set_sidebar_links
    if(@project.exists?)
      @sidebar_links << {
        :controller => "project", 
        :action     => "edit",
        :id         => @project.name,
        :image      => "/images/24x24/wrench.png",
        :name       => "Edit #{@project.name} settings",
      }
    end

#    if(@project.exists?)
#      @sidebar_links << {
#        :controller => "project", 
#        :action     => "delete", 
#        :id         => @project.name,
#        :image      => "/images/24x24/box_delete.png",
#        :name       => "Delete #{@project.name} project"
#      }
#    end

    if(@project.exists? && @project.scm && @project.scm.can_create_central? && !@project.scm.central_exists?)
      @sidebar_links << {
        :controller => "scm", 
        :action     => "create", 
        :id         => @project.name,
        :image      => "/images/24x24/safe_new.png",
        :name       => "Create #{@project.scm.name} repository"
      }
    end

#    if(@project.exists? && !@project.checked_out?)
#      @sidebar_links << {
#        :controller => "scm", 
#        :action     => "checkout", 
#        :id         => @project.name,
#        :image      => "/images/24x24/safe_out.png",
#        :name       => "Check out from #{@project.scm.name}"
#      }
#    end

    if(@project.exists? && @project.checked_out?)
      @sidebar_links << {
        :controller => "files", 
        :action     => "browse",
        :path       => "",
        :id         => @project.name,
        :image      => "/images/24x24/folders.png",
        :name       => "Browse working copy"
      }
    end

    if(@project.exists? && @project.checked_out?)
      @sidebar_links << {
        :controller => "scm", 
        :action     => "delete_working_copy", 
        :id         => @project.name,
        :image      => "/images/24x24/garbage.png",
        :name       => "Delete working copy"
      }
    end

    if(@project.exists? && @project.tracker)
      @sidebar_links << {
        :href       => @project.tracker.url, 
        :image      => "/images/24x24/scroll_information.png",
        :name       => @project.tracker.name
      }
    end

    if(@project.exists? && @project.home_page && @project.home_page != "")
      @sidebar_links << {
        :href       => @project.home_page, 
        :image      => "/images/24x24/home.png",
        :name       => "#{@project.name} home page"
      }
    end

    if(@project.revisions_rss_exists?)
      @sidebar_links << {
        :controller => "project", 
        :action     => "revisions_rss", 
        :id         => @project.name,
        :image      => "/images/rss.gif",
        :name       => "Revisions RSS"
      }
    end

  end

private

  def load
    load_project

    scm = @project.scm
    def scm.selected?
      true
    end
    # Make a dupe of the scm/tracker lists and substitute with project's value
    @scms = RSCM::AbstractSCM.classes.collect {|cls| ;cls.new}
    @scms.each_index {|i| @scms[i] = @project.scm if @scms[i].class == @project.scm.class}

    tracker = @project.tracker
    def tracker.selected?
      true
    end
    @trackers = DamageControl::Tracker::Base.classes.collect {|cls| cls.new}
    @trackers.each_index {|i| @trackers[i] = @project.tracker if @trackers[i].class == @project.tracker.class}

    @linkable_revisions = @project.revisions(@project.latest_revision_identifier, 10)
    @select_revision_identifiers = @project.revision_identifiers[0..-(@linkable_revisions.length+1)]

    set_sidebar_links
  end
end

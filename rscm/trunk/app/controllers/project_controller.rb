require 'rscm'

class ProjectController < ApplicationController

  layout 'rscm'

  def initialize
    super
    @navigation_name = "changesets_list"
  end

  def index
    @projects = RSCM::Project.find_all
    @navigation_name = "null"
  end

  def new
    @project = RSCM::Project.new
    @scms = RSCM::SCMS.dup
    @trackers = RSCM::TRACKERS.dup
    @edit = true
    @new_project = true
    render_action("view")
  end

  def view
    return render_text("No project specified") unless @params["id"]
    @edit = false
    load
  end

  def edit
    @edit = true
    load
    render_action("view")
  end
  
  def changesets_rss
    project = RSCM::Project.load(@params["id"])
    send_file(project.changesets_rss_file)
  end

  def delete
    load_project
    begin
      Rscm.delete_project(project)
    rescue => e
      return render_text("Couldn't connect to RSCM server. Please make sure it's running.<br>" + e.message)
    end
    index
  end

  def save
    project         = instantiate_from_params("project")
    project.scm     = instantiate_from_params("scm")
    project.tracker = instantiate_from_params("tracker")
    
    begin
      Rscm.save_project(project)
    rescue => e
      return render_text("Couldn't connect to RSCM server. Please make sure it's running.<br>" + e.message)
    end

    redirect_to(:action => "view", :id => project.name)
  end
  
  def changesets
    load
    last_changeset_id = @params["changeset"]
    # Later, when we "mix in" DC, we may want to pass a different number than 1 here..
    @changesets = @project.changesets(last_changeset_id, 1)
  end

protected

  def set_sidebar_links
    if(@project.exists?)
      @sidebar_links << {
        :controller => "project", 
        :action     => "edit",
        :id         => @project.name,
        :image      => "/images/24x24/wrench.png",
        :name       => "Edit #{@project.name} settings"
      }
    end

    if(@project.exists?)
      @sidebar_links << {
        :controller => "project", 
        :action     => "delete", 
        :id         => @project.name,
        :image      => "/images/24x24/box_delete.png",
        :name       => "Delete #{@project.name} project"
      }
    end

    if(@project.exists? && @project.scm && !@project.scm.exists? && @project.scm.can_create?)
      @sidebar_links << {
        :controller => "scm", 
        :action     => "create", 
        :image      => "/images/24x24/safe_new.png",
        :name       => "Create #{@project.scm.name} repository"
      }
    end

    if(@project.exists? && !@project.checked_out?)
      @sidebar_links << {
        :controller => "scm", 
        :action     => "checkout", 
        :id         => @project.name,
        :image      => "/images/24x24/safe_out.png",
        :name       => "Check out from #{@project.scm.name}"
      }
    end

    if(@project.exists? && @project.checked_out?)
      @sidebar_links << {
        :controller => "files", 
        :action     => "dir",
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

    if(@project.exists?)
      @sidebar_links << {
        :href       => @project.tracker.url, 
        :image      => "/images/24x24/scroll_information.png",
        :name       => @project.tracker.name
      }
    end

    if(@project.changesets_rss_exists?)
      @sidebar_links << {
        :controller => "project", 
        :action     => "changesets_rss", 
        :id         => @project.name,
        :image      => "/images/rss.gif",
        :name       => "Changesets RSS"
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

    tracker = @project.tracker
    def tracker.selected?
      true
    end

    # Make a dupe of the scm/tracker lists and substitute with project's value
    @scms = RSCM::SCMS.dup
    @scms.each_index {|i| @scms[i] = @project.scm if @scms[i].class == @project.scm.class}

    @trackers = RSCM::TRACKERS.dup
    @trackers.each_index {|i| @trackers[i] = @project.tracker if @trackers[i].class == @project.tracker.class}

    @linkable_changesets = @project.changesets(@project.latest_changeset_id, 10)
    @select_changeset_ids = @project.changeset_ids[0..-(@linkable_changesets.length+1)]

    set_sidebar_links
  end

  # Instantiates an object from parameters
  def instantiate_from_params(param)
    class_name = @params[param]
    clazz = eval(class_name)
    ob = clazz.new
    attribs = @params[class_name] || {}
    attribs.each do |k,v|
      ob.send("#{k}=", v)
    end
    ob
  end

end

require 'rscm'

class ProjectController < ApplicationController

  layout 'rscm'

  def index
    @projects = RSCM::Project.find_all
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
    @edit = false
    load
  end

  def edit
    @edit = true
    load
    render_action("view")
  end
  
  def rss
    project = RSCM::Project.load(@params["id"])
    send_file(project.rss_file)
  end

  def delete
    # TODO: delete it
    render "project/view"
    redirect_to(:controller => "admin", :action => "list")
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

protected

  def set_sidebar_links
    if(@project && @project.scm && !@project.scm.exists? && @project.scm.can_create?)
      @sidebar_links << {
        :controller => "scm", 
        :action     => "create", 
        :image      => "/images/24x24/safe_new.png",
        :name       => "Create #{@project.scm.name} repository"
      }
    end

    if(@project && @project.scm && @project.scm.exists?)
      @sidebar_links << {
        :controller => "scm", 
        :action     => "checkout", 
        :image      => "/images/24x24/safe_out.png",
        :name       => "Check out from #{@project.scm.name} now"
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

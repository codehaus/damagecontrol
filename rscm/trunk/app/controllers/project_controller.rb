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
    
    Rscm.save_project(project)

    redirect_to(:action => "view", :id => project.name)
  end

private

  def load
    project_name = @params["id"]
    @project = RSCM::Project.load(project_name)

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

class ProjectController < ApplicationController

  layout 'rscm'

  def index
    @projects = RSCM::Project.find_all
  end

  def view
    project_name = @params["id"]
    if(project_name)
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
    else
      @project = RSCM::Project.new
      @scms = RSCM::SCMS.dup
      @trackers = RSCM::TRACKERS.dup
    end    
    
    # TODO: loop through query params and override the selected?
    # method for the one that has matching class name to the scm_name param
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
    
    project.save

    redirect_to(:action => "view", :id => project.name)
  end

private

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

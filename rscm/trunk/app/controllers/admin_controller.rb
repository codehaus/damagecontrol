require 'rscm'
require 'erb'
require 'yaml'

# Add some generic web capabilities to the RSCM classes

module RSCM
  module Web
    module Configuration

      def javascript
        template(:javascript_file)
      end

      def selected?
        false
      end

      # Returns the configured form to be inlined in the HTML
      def config_form
        template(:form_file)
      end

    private

      def template(symbol)
        if(respond_to?(symbol) && File.exist?(send(symbol)))
          template = File.read(File.expand_path(send(symbol)))
          erb = ERB.new(template, nil, '-')
          erb.result(binding)
        else
          "<!-- No template for #{self.class.name}.{symbol.to_s} -->"
        end
      end

    end
  end
end

class RSCM::AbstractSCM
  include RSCM::Web::Configuration
end

class RSCM::Tracker::Base
  include RSCM::Web::Configuration
end

class RSCM::Project
  include RSCM::Web::Configuration
end

class AdminController < ApplicationController

  layout 'rscm'

  def add # user will post to save
    @project = RSCM::Project.new
    @scms = RSCM::SCMS.dup
    @trackers = RSCM::TRACKERS.dup
    render "admin/project"
  end
  
  def save
    project         = instantiate_from_params("project")
    project.scm     = instantiate_from_params("scm")
    project.tracker = instantiate_from_params("tracker")
    
    File.open("#{project.name}.yaml", "w") do |io|
      YAML::dump(project, io)
    end

    redirect_to(:action => "show", :id => project.name)
  end

  def show
    project_name = @id
    File.open("#{project_name}.yaml") do |io|
      @project = YAML::load(io)
    end
    
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
    
    # TODO: loop through query params and override the selected?
    # method for the one that has matching class name to the scm_name param
    render "admin/project"
  end
  
  def list
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

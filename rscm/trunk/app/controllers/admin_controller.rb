require 'rscm'
require 'erb'
require 'yaml'

# Add some generic web capabilities to the SCM classes
class RSCM::AbstractSCM

  def javascript_on_load
    ""
  end

  def javascript
    ""
  end
  
  def selected?
    false
  end
  
  def config_form
    if(respond_to?(:form_file) && File.exist?(form_file))
      template = File.read(File.expand_path(form_file))
      erb = ERB.new(template, nil, '-')
      erb.result(binding)
    else
      ""
    end
  end
end

class AdminController < ApplicationController

  layout 'rscm'
  SCMS = [RSCM::CVS, RSCM::SVN, RSCM::StarTeam]

  def add
    init

    render "admin/project"
  end
  
  def show
    # TODO: YAML load from file based on project id

    init

    # TODO: loop through query params and override the selected?
    # method for the one that has matching class name to the scm_name param

    render "admin/project"
  end
  
  def save
    scm = instantiate_from_params("scm")
    # TODO instantiate more objects and YAML everything to file...
    
    redirect_to(:action => "show")
  end

  def list
  end
  
private

  # Instantiates an object from parameters
  def instantiate_from_params(param)
    class_name = @params[param]
    clazz = eval(class_name)
    ob = clazz.new
    attribs = @params[class_name]
    attribs.each do |k,v|
      ob.send("#{k}=", v)
    end
    ob
  end

  def init
    @scm_map = {}
    @scms = []
    SCMS.each do |c|
      scm = c.new
      @scm_map[c] = scm
      @scms << scm
    end

    # TODO similar
    @tracking_configurators = []

    # TODO replace with Project class
    @project_name = ""
    @project_config = {}
    
  end

end

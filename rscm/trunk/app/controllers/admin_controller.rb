require 'rscm'
require 'erb'

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
      ERB.new(File.new(form_file).read.untaint).result(binding)
    else
      ""
    end
  end
end

class AdminController < ApplicationController

  layout 'rscm'
  
  def add
    @project_config = {}
    @project_name = ""
    @scms = [RSCM::CVS.new, RSCM::SVN.new, RSCM::StarTeam.new]
    # TODO: loop through query params and override the selected?
    # method for the one that has matching class name to the scm_name param
    
    @tracking_configurators = []
  end
  
  def show
    render("add")
  end
  
  def save
    # do all the saving stuff....
    redirect_to(:action => "show")
  end

  def list
  end
end

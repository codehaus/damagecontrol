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
      File.expand_path(form_file)
    else
      nil
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
    init

    # TODO: loop through query params and override the selected?
    # method for the one that has matching class name to the scm_name param

    render "admin/project"
  end
  
  def save
    # TODO do all the saving stuff....
    redirect_to(:action => "show")
  end

  def list
  end
  
private

  def init
    @config_forms = Hash.new("NO FORM")
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

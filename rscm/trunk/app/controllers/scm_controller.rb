require 'rscm/directories'

class ScmController < ApplicationController

  layout 'rscm'

  def checkout
    project_name = @params["id"]
    if(project_name)
      project = RSCM::Project.load(project_name)
      # We'll check out asynch (takes time!)
      Thread.new do
#        project.checkout
      end

      # Doing a redirect since this *should* be called via HTTP POST
      redirect_to :action => "checkout_status", :id => project_name
    else
      # TODO: show a better error page.
      render_text "No project specified"
    end
  end

  # Shows the status page with the JS magic that
  # will pull the checkout_list
  def checkout_status
    @checkout_list_path = "/scm/checkout_list/#{@params['id']}"
  end

  # Returns a txt file containing the files currently being checked out.
  def checkout_list
    project_name = @params["id"]
    file_name = RSCM::Directories.checkout_list_file(project_name)
    send_file(file_name)
  end

end

require 'rscm/directories'

class ScmController < ApplicationController

  layout 'rscm'

  # Checks out a working copy into the project's checkout dir.
  def checkout
    project = load_project

    # We'll check out asynch (takes time!)
#    Thread.new do
      project.checkout
#    end

    # Doing a redirect since this *should* be called via HTTP POST. TODO: verify METHOD
#    redirect_to :action => "checkout_status", :id => project.name
    render_text("HALLO")
  end

  # Shows the status page with the JS magic that
  # will pull the checkout_list
  def checkout_status
    @checkout_list_path = "/scm/checkout_list/#{@params['id']}"
  end

  # Sends the file containing the files currently being checked out.to the client
  def checkout_list
    project = load_project
    if(File.exist?(project.checkout_list_file))
      send_file(project.checkout_list_file)
    else
      render_text("No files checked out yet")
    end
  end

  # Creates the SCM repo
  def create
    project = load_project
    project.scm.create
    redirect_to :controller => "project", :action => "view", :id => project.name
  end

end

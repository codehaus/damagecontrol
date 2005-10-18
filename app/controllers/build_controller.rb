class BuildController < ApplicationController
  
  def show
    find
    # TODO: optimize
    @project = @build.project
    @revisions = @build.revision.project.revisions
    load_builds_for_sparkline(@project)
    @template_for_left_column = "revision/list"
  end

  def stdout
    send_log(find.stdout_file)
  end

  def stderr
    send_log(find.stderr_file)
  end

private

  def find
    @build = Build.find(@params[:id])
  end

  def send_log(file)
    if(File.exist?(file))
      send_file(file, :type => "text/plain", :disposition => "inline")
    else
      render :text => "Build not started"
    end
  end

end

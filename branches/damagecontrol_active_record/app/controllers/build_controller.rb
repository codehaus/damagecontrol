class BuildController < ApplicationController
  
  layout nil

  def show
    find
    @project = @build.project
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
      render :text => @build.completed? ? "File #{file} not found. It has probably been deleted" : "Build not started"
    end
  end

end

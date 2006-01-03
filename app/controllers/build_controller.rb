class BuildController < ApplicationController
  
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

end

class BuildController < ApplicationController

  def status
  end

  def stdout
    load_build
    send_log(@build.stdout_file)
  end

  def stderr
    load_build
    send_log(@build.stderr_file)
  end

  def tests
  end

private

  def send_log(file)
    # see application.rb for :no_disposition
    send_file(file, :stream => true, :type => "text/plain", :no_disposition => true)
  end

  def load_build
    load_project
    changeset_identifier = @params["changeset"].to_identifier
    build_time = @params["build"].to_identifier
    @build = @project.changeset(changeset_identifier).build(build_time)
  end

end

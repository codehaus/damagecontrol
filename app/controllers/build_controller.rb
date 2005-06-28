require 'yaml'
require 'fileutils'

class BuildController < ApplicationController

  layout nil

  # Requests a build for a Revision
  def request_build
    load_project
    @revision_identifier = @params["revision"].to_identifier
    reason = @params["reason"] || "Triggered via HTTP (unknown why)"
    # Persist the request so it can be picked up by the daemon
    FileUtils.mkdir_p("#{BASEDIR}/build_requests")
    File.open("#{BASEDIR}/build_requests/#{@project.name}_#{@revision_identifier}.yaml", 'w') do |io|
      YAML::dump({
        :project_name => @project.name, 
        :revision_identifier => @revision_identifier, 
        :reason => reason
      }, io)
    end
  end

  def stdout
    load_build
    send_log(@build.stdout_file)
  end

  def stderr
    load_build
    send_log(@build.stderr_file)
  end

private

  def send_log(file)
    # see application.rb for :no_disposition
    send_file(file, :stream => true, :type => "text/plain", :no_disposition => true)
  end

  def load_build
    load_project
    revision_identifier = @params["revision"].to_identifier
    build_time = @params["build"].to_identifier
    @build = @project.revision(revision_identifier).build(build_time)
  end

end

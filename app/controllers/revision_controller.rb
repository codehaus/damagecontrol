require 'zip/zip'

class RevisionController < ApplicationController
  verify :method => :post, :only => %w( request_build result_zip )

  layout nil

  def show
    @revision = Revision.find(@params[:id])
    @scm_files = @revision.scm_files

    @revision_message = @revision.message
  end

  # Requests build(s). Should be called via an AJAX POST.
  def request_build
    @revision = Revision.find(@params[:id])
    builds = @revision.request_builds(Build::MANUALLY_TRIGGERED)
    message = builds.nil? ? "Request ignored - there are currently unfinished builds for this revision" : "Build requested"
    render :text => message
  end

  # Returns a zipped revision
  def zip
    revision = Revision.find(@params[:id])
    zipfile = revision.project.zip_dir + "/#{revision.id}.zip"
    if(File.exist?(zipfile))
      send_file zipfile, :type => "application/zip"
    else
      render :text => "Couldn't find #{zipfile}"
    end
  end
  
  def result_zip
    revision = Revision.find(@params[:id])
    zipfile = revision.project.zip_dir + "/#{revision.id}_result.zip"
    File.open(zipfile, "wb") do |io|
      io.write(@params[:zip].read)
    end
    render :text => "OK:#{request.raw_post.length}"
  end
  
protected

  def tip_category
    :commit_msg
  end

  
end

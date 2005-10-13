require 'zip/zip'

class RevisionController < ApplicationController

  layout "application", :except => :list

  def list
    @project = Project.find(@params[:id])
    @revisions = @project.revisions
    
    load_builds_for_sparkline(@project)
  end
  
  def show
    @revision = Revision.find(@params[:id])

    # first rendering of revision list
    @project = @revision.project
    @revisions = @revision.project.revisions
    @template_for_left_column = "revision/list"
    
    @revision_message = @revision.message

    load_builds_for_sparkline(@project)
  end

  # Requests build(s). Should be called via an AJAX POST.
  def build
    @revision = Revision.find(@params[:id])
    @revision.request_builds(Build::MANUALLY_TRIGGERED)
    render :text => "Build requested"
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
    if(request.post?)
      revision = Revision.find(@params[:id])
      zipfile = revision.project.zip_dir + "/#{revision.id}_result.zip"
      File.open(zipfile, "wb") do |io|
        io.write(@params[:zip].read)
      end
      render :text => "OK:#{request.raw_post.length}"
    else
      render :text => "KO"
    end
  end
  
protected

  def tip_category
    :commit_msg
  end

  
end

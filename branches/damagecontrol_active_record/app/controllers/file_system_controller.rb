require 'mime/types' # http://rubyforge.org/projects/mime-types/

# DEPRECATED. Will be superceded by RSCM controller

class FileSystemController < ApplicationController

  def browse
    @path_array = @params[:path] || []
    # TODO: extra param to denote the root:
    # :project_id => working copy of project
    # :artifacts => artifacts root dir
    all = [Artifact::ARTIFACT_DIR] + @path_array
    file_name = File.join(all)
    if(File.directory?(file_name))
      @dir = file_name
      render :action => "dir"
    else
      # TODO: Make this work with stream. Keep getting warnings in the console:
      # /usr/local/lib/ruby/gems/1.8/gems/actionpack-1.9.1/lib/action_controller/streaming.rb:71: warning: syswrite for buffered IO
      
      mime_types = MIME::Types.type_for(file_name)
      mime_type = mime_types.empty? ? "application/octet-stream" : mime_types[0].to_s
      send_file(file_name, :disposition => "inline", :stream => false, :type => mime_type)
    end
  end

end

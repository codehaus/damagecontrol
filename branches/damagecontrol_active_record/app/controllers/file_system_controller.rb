class FileSystemController < ApplicationController
  # TODO: use http://rubyforge.org/projects/mime-types/
  MIME_TYPES = Hash.new("application/octet-stream")
  def type
    MIME_TYPES[extname]
  end


  def artifacts
    @path_array = @params[:path] || []
    all = [Artifact::ARTIFACT_DIR] + @path_array
    file_name = File.join(all)
    if(File.directory?(file_name))
      @dir = file_name
      render :action => "dir"
    else
      # TODO: Make this work with stream. Keep getting warnings in the console:
      # /usr/local/lib/ruby/gems/1.8/gems/actionpack-1.9.1/lib/action_controller/streaming.rb:71: warning: syswrite for buffered IO
      # TODO: Look up content-type in a lookup table. maybe from the OS (if POSIX at least)
      send_file(file_name, :disposition => "inline".freeze, :stream => false, :type => "text/plain".freeze)
    end
  end

end

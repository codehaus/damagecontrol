require 'pathname'

class FileSystemController < ApplicationController

  def artifacts
    @path_array = @params[:path] || []
    file = Pathname.new(Artifact::ARTIFACT_DIR + '/' + @path_array.join('/'))
    if(file.directory?)
      @dir = file
      render :action => "dir"
    else
      # TODO: Make this work with stream. Keep getting warnings in the console:
      # /usr/local/lib/ruby/gems/1.8/gems/actionpack-1.9.1/lib/action_controller/streaming.rb:71: warning: syswrite for buffered IO
      # TODO: Look up content-type in a lookup table. maybe from the OS (if POSIX at least)
      send_file(file.realpath, :disposition => "inline".freeze, :stream => false, :type => "text/plain".freeze)
    end
  end

end

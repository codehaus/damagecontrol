class FileSystemController < ApplicationController

  def dir
    @dir = Directory.lookup(@params[:path])
  end

end

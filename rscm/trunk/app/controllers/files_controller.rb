require 'rscm/directories'

class FilesController < ApplicationController

  layout 'rscm'

  def dir
    load_project
    
    @files = Dir["#{@project.checkout_dir}/*"]
  end
end

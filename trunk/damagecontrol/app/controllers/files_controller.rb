class FilesController < ApplicationController
  
  before_filter :load_project

  def list  
    root = @project.checkout_dir
    relative_path = @params['path']
    absolute_path = relative_path ? "#{root}/#{relative_path}" : root
    if(File.file?(absolute_path))
      # TODO: use http://rubyforge.org/projects/syntax/
      # TODO: the file contents should be rendered within the regular layout
      render_text(File.open(absolute_path).read)
    else
      @relative_paths = Dir["#{absolute_path}/*"].collect {|f| f[root.length+1..-1]}
    end
  end
end

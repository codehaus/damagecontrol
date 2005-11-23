require 'mime/types' # http://rubyforge.org/projects/mime-types/

# This Controller can show contents of an SCM or File system.
class RscmController < ActionController::Base
  def browse
    path = @params[:path].to_s
    @history_files = scm.ls(path)
  end
  
  def view_file
    path = @params[:path].to_s
    history_file = scm.file(path, false)
    revision_file = history_file.revision_files[0]
    revision_file.open(scm) do |io|
      mime_types = MIME::Types.type_for(path)
      mime_type = mime_types.empty? ? "text/plain" : mime_types[0].to_s
      send_data io.read, :type => mime_type, :disposition => "inline"
    end
  end

protected

  def scm
    @id = @params[:id]
    scm = Project.find(@id).scm
  end
end
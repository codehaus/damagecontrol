require 'mime/types' # http://rubyforge.org/projects/mime-types/

# This Controller can show contents of an SCM or File system.
class RscmController < ActionController::Base
  
  # TODO: we really have to use RDBMS objects here since we want to display (for each file)
  #  * latest revision
  #  * latest timestamp
  #  * latest author
  #  * latest message
  #
  # The scm.ls methods won't give us that info (it's not in the cvs logs afaik)
  # It's probably too hard to do all of this in RSCM, so we might have to do it in DC/RDBMS
  # Therefore, we should use RDBMS persisted revisions where this is probably easier.
  # We have to look at how it fits in with the metrics stuff too.
  def browse
    @path = @params[:path].to_s
    @history_files = scm.ls(@path)
  end
  
  def cbrowse
    @path = @params[:path].to_s
    @history_files = scm.ls(@path)
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
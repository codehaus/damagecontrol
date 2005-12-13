require 'mime/types' # http://rubyforge.org/projects/mime-types/

# This Controller can show contents of an SCM or File system.
class RscmController < ActionController::Base
  
  def browse
    project = Project.find(@params[:id])
    @path = @params[:path].to_s
    @revision_identifier = @params[:rev].nil? ? nil : project.scm.to_identifier(@params[:rev].to_s)
    
    parent_file = ScmFile.find_by_path_and_project_id(@path, project.id)
    parent_file_rev = parent_file.revisions.latest(@revision_identifier)
    if(parent_file_rev)
      render :text => "#{@path} did not yet exist at revision #{@revision_identifier}"
    else
      @files = parent_file.children
    end
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

  def url_for_file(file, revision=nil)
    path_parts = file.path.split('/').reject {|fp| fp.empty?}
    path_url = {:action => 'browse', :path => path_parts}
    if revision
      url = path_url.merge({:rev => file.directory? ? revision.identifier : revision.native_revision_identifier})
    else
      url = path_url
    end
    url_for(url)
  end
  helper_method :url_for_file

protected

  def scm
    @id = @params[:id]
    scm = Project.find(@id).scm
  end
end
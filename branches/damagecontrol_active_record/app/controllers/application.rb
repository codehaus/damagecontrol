# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.
class ApplicationController < ActionController::Base

  before_filter :load_projects
  
  # Extracts an object from @params
  def extract(name)
    plural_name = "#{name}s".to_sym
    class_name = @params[name]
    object = eval(class_name).new
    attrs = @params[plural_name][class_name]
    attrs.each do |attr_name, attr_value|
      setter = "#{attr_name}=".to_sym
      object.__send__(setter, attr_value) if object.respond_to?(setter)
    end
    object
  end

private

  # Loads all projects so that the right column can be populated properly
  def load_projects
    @projects = Project.find(:all)
  end
end

class Build < ActiveRecord::Base
  def small_image
    if(successful?)
      "green-32.gif"
    else
      "red-32.gif"
    end
  end
end

class RevisionFile < ActiveRecord::Base
  IMAGES = {
    RSCM::RevisionFile::ADDED => "document_new",
    RSCM::RevisionFile::DELETED => "document_delete",
    RSCM::RevisionFile::MODIFIED => "document_edit",
    RSCM::RevisionFile::MOVED => "document_exchange"
  }
  
  DESCRIPTIONS = {
    RSCM::RevisionFile::ADDED => "New file",
    RSCM::RevisionFile::DELETED => "Deleted file",
    RSCM::RevisionFile::MODIFIED => "Modified file",
    RSCM::RevisionFile::MOVED => "Moved file"
  }
  
  def image
    IMAGES[status]
  end
  
  def status_description
    DESCRIPTIONS[status]
  end

end

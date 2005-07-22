class ApplicationController < ActionController::Base

  before_filter :load_projects
  
  def deserialize_to_array(hash)
    result = []
    hash.each do |class_name, values|
      result << deserialize(class_name, values)
    end
    result
  end

  # Deserialises an object from a Hash where one attribute is the class name
  # and the rest of them are attribute values.
  def deserialize(class_name, attributes)
    object = eval(class_name).new
    attributes.each do |attr_name, attr_value|
      setter = "#{attr_name}=".to_sym
      object.__send__(setter, attr_value) #if object.respond_to?(setter)
    end
    object
  end

private

  # Loads all projects so that the right column can be populated properly
  def load_projects
    @projects = Project.find(:all)
  end
end

class RSCM::Base
  # Change detection types
  POLLING = "POLLING"
  TRIGGER = "TRIGGER"
  
  attr_accessor :selected
  attr_accessor :change_detection
  
  def <=> (o)
    self.class.name <=> o.class.name
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

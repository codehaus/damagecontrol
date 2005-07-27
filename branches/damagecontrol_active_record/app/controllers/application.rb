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
      object.__send__(setter, attr_value)
    end
    object
  end

private

  # Loads all projects so that the right column can be populated properly
  def load_projects
    @projects = Project.find(:all)
  end
end

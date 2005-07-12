# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.
class ApplicationController < ActionController::Base
  
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

require_dependency 'sparklines'
require 'damagecontrol'

class ApplicationController < ActionController::Base
  SPARKLINE_COUNT = 20
  
  COMMIT_MSG_TIPS = [
    "bug_ids_commit_msg",
    "textile_commit_msg",
    "bug_edit_commit_msg"
  ]
  PROJECT_SETTING_TIPS = [
#    "triggering",
    "importing"
  ]
  TIPS = {
    :project_settings => PROJECT_SETTING_TIPS,
    :commit_msg => COMMIT_MSG_TIPS,
    :any => COMMIT_MSG_TIPS + PROJECT_SETTING_TIPS
  }

  before_filter :load_projects, :random_tip
  helper :sparklines
  
  def deserialize_to_array(hash)
    result = []
    hash.each do |class_name, values|
      result << deserialize(class_name, values)
    end
    result
  end

  # Deserialises an object from a Hash holding attribute values. 
  # Special rules:
  # * "true" and "false" strings are turned into booleans.
  # * Array values are eval'ed to classes and new'ed.
  # * Hash values are turned into a new Hash by combining its
  #   :keys and :values entries (This is handier to POST from forms).
  # * attribute names ending with '_yaml' will have '_yaml' stripped
  #   off and the value will be YAML::load'ed from the original value.
  #
  def deserialize(class_name, attributes)
    object = eval(class_name).new
    attributes.each do |attr_name, attr_value|
      if(attr_value == "true")
        attr_value = true
      elsif(attr_value == "false")
        attr_value = false
      elsif(attr_name =~ /(.*)_yaml/)
        attr_value = YAML::load(attr_value)
        attr_name = $1
      elsif(attr_value.is_a?(Array))
        attr_value = instantiate_array(attr_value)
      elsif(attr_value.is_a?(Hash))
        keys = attr_value[:keys]
        values = attr_value[:values]
        attr_value = {}
        keys.each_with_index do |key, i|
          attr_value[key] = values[i]
        end
      end

      setter = "#{attr_name}=".to_sym
      object.__send__(setter, attr_value)
    end
    object
  end

protected
  
  def load_builds_for_sparkline(project)
    @builds = project.builds(nil, nil, SPARKLINE_COUNT)
  end

  def random_tip
    # TODO: perhaps keep a counter in the session and show sequentially?
    tips = TIPS[tip_category]
    tip(tips[rand(tips.length)])
  end
  
  # subclasses can override this method to specify a more specific tip category
  def tip_category
    :any
  end
  
  # call this method from an action to display a specific tip
  def tip(template_name)
    @template_for_tip = "tips/#{template_name}"
  end

private

  def instantiate_array(array)
    result = array.collect do |cls_name| 
      eval(cls_name).new
    end
  end

  # Loads all projects so that the right column can be populated properly
  def load_projects
    @projects = Project.find(:all)
  end
end

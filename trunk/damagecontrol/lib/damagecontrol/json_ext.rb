begin
  
require 'yaml'
require 'rubygems'
require_gem 'ruby-json'
require 'json/objects'

class Object
  # Turns an object into json using its Hash representation.
  def to_json
    r = Hash.new
    to_yaml_properties.each do |p|
      r[p[1..-1]] = self.instance_variable_get(p)
    end
    r.to_json
  end
end

rescue Gem::LoadError
  # appropriate gem not installed, disabling json support
end
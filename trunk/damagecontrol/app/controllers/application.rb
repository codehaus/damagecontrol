# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.

require 'rscm_ext'
require 'rails_ext'
require 'damagecontrol/project'
require 'damagecontrol/build'
require 'damagecontrol/tracker'
require 'damagecontrol/scm_web'
# TODO: find a way so we don't have to explicitly load these
require 'damagecontrol/publisher/email'
require 'damagecontrol/publisher/irc'
require 'damagecontrol/publisher/growl'

class ApplicationController < ActionController::Base

  layout 'rscm'

  def initialize
    @sidebar_links = [
      {
        :controller => "project", 
        :action     => "new", 
        :image      => "/images/24x24/box_new.png",
        :name       => "New project"
      }
    ]
    @controller = self
  end

  # Loads the project specified by the +id+ parameter and places it into the @project variable  
  def load_project
    project_name = @params["id"]
    @project = DamageControl::Project.load(project_name)
  end

  def breadcrumbs
    subpaths = @request.path.split(/\//)
#    subpaths.collect { |p| link_to_unless_current(p) }.links.join(" ")
  end

  # Instantiates an Array of object from +class_name_2_attr_hash_hash+
  # which should be a hash where the keys are class names and the values
  # a Hash containing {attr_name => attr_value} pairs.
  def instantiate_array_from_hashes(class_name_2_attr_hash_hash)
    result = []
    class_name_2_attr_hash_hash.each do |class_name, attr_hash|
      result << instantiate_from_hash(eval(class_name), attr_hash)
    end
    result
  end

  def instantiate_from_hash(clazz, attr_hash)
    object = clazz.new
    attr_hash.each do |attr_name, attr_value|
      object.instance_variable_set(attr_name, attr_value)
    end
    object
  end

  # Returns an object from a select_pane
  def selected(name)
    array = instantiate_array_from_hashes(@params[name])
    selected = @params["#{name}_selected"]
    array.find { |o| o.class.name == selected }
  end
    
protected

  # Override so we can get rid of the Content-Disposition
  # headers by specifying :no_disposition => true in options
  # This is needed when we want to send big files that are
  # *not* intended to pop up a save-as dialog in the browser,
  # such as content to display in iframes (logs and files)
  def send_file_headers!(options)
    options.update(DEFAULT_SEND_FILE_OPTIONS.merge(options))
    [:length, :type, :disposition].each do |arg|
      raise ArgumentError, ":#{arg} option required" if options[arg].nil?
    end

    headers = {
      'Content-Length'            => options[:length],
      'Content-Type'              => options[:type]
    }
    unless(options[:no_disposition])
      disposition = options[:disposition].dup || 'attachment'
      disposition <<= %(; filename="#{options[:filename]}") if options[:filename]
      headers.merge!(
        'Content-Disposition'       => disposition,
        'Content-Transfer-Encoding' => 'binary'
      )
    end
        
    @headers.update(headers);
  end

  # Sets the links to display in the sidebar. Override this method in other controllers
  # To change what to display.
  def set_sidebar_links

  end
  
end

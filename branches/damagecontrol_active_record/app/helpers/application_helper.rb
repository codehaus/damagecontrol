require_dependency 'build'

module ApplicationHelper
  
  def field(object, name, attr_name, type="text", id=nil)
    tag("input", 
      :name => "#{name}[#{attr_name[1..-1]}]", 
      :value => object.instance_variable_get(attr_name),
      :type => type,
      :id => id
    )
  end

  def artifact_link(artifact)
    link_to(
      File.basename(artifact.relative_path), 
      :controller => "file_system", :action => "artifacts", :params => {:path => artifact.relative_path.split('/')}
    )
  end
  
  def enabled_field(object)
    field(object, "#{object.category}[#{object.class.name}]", "@enabled", "hidden", object.enabled_id)
    # <input id="<%= object.enabled_id %>" name="scm[<%= object.class.name %>][enabled]" value="<%= object.enabled %>">
  end
  
  def description(clazz, attr_name)
    attr_name[1..-1]
  end

  # Renders +object+'s attributes as form fields in a table. Each field's name
  # will be prefixed by +prefix+. If +object+ responds to a method named 'default_render_excludes'
  # that returns an array, the attributes matching the symbols in this array will 
  # be omitted from rendering.
  def render_object(object, prefix)
    default_render_excludes = object.respond_to?(:default_render_excludes) ? object.default_render_excludes : []
    render :partial => 'shared/object', 
           :locals => {:object => object, :prefix => prefix, :default_render_excludes => default_render_excludes}
  end

  def has_template(category, name)
    template_file = File.expand_path(RAILS_ROOT + 
      "/app/views/#{category}/_#{name}.rhtml")
    File.exist?(template_file)
  end
  
  def template_for(category, name)
    template_name = "#{category}/#{name}"
  end
  
  # Checkbox tag for publishers' enabling states
  def enabling_state_tag(object, state_class_name)
    enabled = object.enabling_states && !object.enabling_states.find{|state| state.class.name == state_class_name}.nil?
    check_box_tag("#{object.category}[#{object.class.name}][enabling_states][]", state_class_name, enabled, {:onchange => "publisherChanged('#{object.dom_id}');return false;", :id => nil})
  end
end

########### Add methods required by view. TODO: Maybe put in different file, domain_ui_ext.rb or something? ########### 

module DamageControl
  # This module should be included by domain objects that can be enabled or disabled in the UI.
  module Icons
    def enabled_icon
      "#{icon_base}.png"
    end

    def disabled_icon
      "#{icon_base}_grey.png"
    end

    # Returns +enabled_icon+ if the instance is +enabled+, or
    # +disabled_icon+ if not.
    def current_icon
      enabled ? enabled_icon : disabled_icon
    end
  end
  
  # This module adds HTML DOM methods to objects
  module Dom
    
    # A unique HTML DOM id that is W3C compliant
    def dom_id
      "#{category}_#{self.class.name.demodulize.underscore}"
    end

    def enabled_id
      "#{dom_id}_enabled"
    end

  end
end

class Project < ActiveRecord::Base
  include ::DamageControl::Icons
  include ::DamageControl::Dom

  def icon_base
    "goldbar"
  end
  
  def enabled
    true
  end
  
  def category
    "project"
  end

  def exclusive?
    false
  end
end

module RSCM
  
  class Base
    include ::DamageControl::Icons
    include ::DamageControl::Dom

    # Available change detection types
    POLLING = "POLLING" unless defined? POLLING
    TRIGGER = "TRIGGER" unless defined? TRIGGER

    attr_accessor :enabled
    attr_accessor :change_detection

    def <=> (o)
      self.class.name <=> o.class.name
    end

    def icon_base
      "/images/#{category}/#{self.class.name.demodulize.underscore}"
    end
    
    def category
      "scm"
    end

    def exclusive?
      true
    end

    def default_render_excludes
      [:enabled, :fileutils_label, :fileutils_output]
    end
  end
end

module DamageControl
  class Plugin
    include Icons
    include Dom
    
    def icon_base
      "/images/#{category}/#{self.class.name.demodulize.underscore}"
    end

    def default_render_excludes
      [:enabled, :fileutils_label, :fileutils_output]
    end
  end
  
  module Publisher
    class Base
      def category
        "publisher"
      end
      
      def exclusive?
        false
      end

      # Exclude default rendering of enabling_states. It's handled by the _publisher.rhtml
      # template.
      def default_render_excludes
        [:enabling_states, :fileutils_label, :fileutils_output]
      end
    end
  end

  module Tracker
    class Base
      def category
        "tracker"
      end

      def exclusive?
        true
      end
    end
  end

  module ScmWeb
    class Base
      def category
        "scm_web"
      end

      def exclusive?
        true
      end
    end
  end
end

class Build < ActiveRecord::Base
  def icon
    if(successful?)
      "green-32.gif"
    else
      "red-32.gif"
    end
  end
end

class RevisionFile < ActiveRecord::Base
  ICONS = {
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
  
  def icon
    ICONS[status]
  end
  
  def status_description
    DESCRIPTIONS[status]
  end

end

class Pathname
  DEFAULT_ICON_PATH = '/images/filetypes/txt.gif'
  
  def icon
    icon_path = '/images/filetypes/#{extname}.gif'
    File.exist?(RAILS_ROOT + '/public' + icon_path) ? icon_path : DEFAULT_ICON_PATH
  end
end
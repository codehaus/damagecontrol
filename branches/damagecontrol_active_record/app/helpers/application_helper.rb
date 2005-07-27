# The methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def field(object, name, attr_name)
    tag("input", :name => "#{name}[#{attr_name[1..-1]}]", :value => object.instance_variable_get(attr_name))
  end
  
  def description(clazz, attr_name)
    attr_name[1..-1]
  end

  def render_object_with_name(object, prefix)
    render :partial => 'shared/object', 
           :locals => {:object => object, :prefix => prefix}
  end

  def has_template(category, name)
    template_file = File.expand_path(RAILS_ROOT + 
      "/app/views/#{category}/_#{name}.rhtml")
    File.exist?(template_file)
  end
  
  def template_for(category, name)
    template_name = "#{category}/#{name}"
  end
end

########### Add methods required by view ########### 

class Project < ActiveRecord::Base
  def icon
    "goldbar"
  end
  
  def family
    "project"
  end
end

module RSCM
  class Base
    # Change detection types
    POLLING = "POLLING" unless defined? POLLING
    TRIGGER = "TRIGGER" unless defined? TRIGGER

    attr_accessor :selected
    attr_accessor :change_detection

    def <=> (o)
      self.class.name <=> o.class.name
    end

    def icon
      base = "/images/#{family}/#{self.class.name.demodulize.underscore}"
      selected ? "#{base}.png" : "#{base}_grey.png"
    end
    
    def family
      "scm"
    end
  end
end

module DamageControl
  class Plugin
    def icon
      "/images/#{family}/#{self.class.name.demodulize.underscore}.png"
    end
  end
  
  module Publisher
    class Base
      def family
        "publisher"
      end
    end
  end

  module Tracker
    class Base
      def family
        "tracker"
      end
    end
  end

  module ScmWeb
    class Base
      def family
        "scm_web"
      end
    end
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

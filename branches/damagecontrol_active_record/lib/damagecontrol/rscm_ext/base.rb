module RSCM

  class Base
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

    def has_link?
      false
    end
    
    def path_prefix
      ""
    end
  end
  
  class Cvs    
    def view_cvs_full_path(revision_file)
      deleted_prefix = revision_file.status == RevisionFile::DELETED ? "Attic/" : ""
      path_elements = revision_file.path.split("/")
      dir = path_elements[0..-2].join("/") + "/"
      file = path_elements[-1]
      "#{self.mod}/#{dir}#{deleted_prefix}#{file}"
    end
  end
end

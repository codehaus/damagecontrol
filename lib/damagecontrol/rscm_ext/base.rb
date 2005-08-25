module RSCM

  class Base
    include ::DamageControl::Dom

    # Available change detection types
    POLLING = "POLLING" unless defined? POLLING
    TRIGGER = "TRIGGER" unless defined? TRIGGER

    attr_accessor :enabled
    attr_accessor :change_detection

    def category
      "scm"
    end

    def exclusive?
      true
    end

    def path_prefix
      ""
    end

    def damage_control_full_path(revision_file)
      revision_file.path
    end

  end
  
  class Cvs < Base
    def scm_web_path(revision_file)
      deleted_prefix = revision_file.status == RevisionFile::DELETED ? "Attic/" : ""
      path_elements = revision_file.path.split("/")
      dir = path_elements[0..-2].join("/") + "/"
      file = path_elements[-1]
      "#{dir}#{deleted_prefix}#{file}"
    end
  end

  class Subversion < Base
    def scm_web_path(revision_file)
      revision_file.path
    end
  end

end

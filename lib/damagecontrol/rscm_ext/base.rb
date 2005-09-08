module RSCM

  class Base
    include ::DamageControl::Dom

    attr_accessor :enabled
    attr_accessor :uses_polling # String, posted from web form.

    def category
      "scm"
    end
    
    def uses_polling?
      # If not set at all, default to true
      return true if @uses_polling.nil?
      @uses_polling.to_i != 0
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

module RSCM

  class Base
    include ::DamageControl::Dom

    attr_accessor :enabled
    attr_accessor :uses_polling

    def self.classes
      # Only Subversion and Cvs are known to be stable...
      [RSCM::Subversion, RSCM::Cvs, RSCM::ClearCase, RSCM::Perforce, RSCM::Monotone]
    end

    def category
      "scm"
    end
    
    def exclusive?
      true
    end

    def path_prefix
      ""
    end

    def scm_web_path(revision_file)
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

end

require 'rscm/path_converter'

module DamageControl
  module SCMWeb

    class Null
      def file_url(file, anchor=false)
        file.path
      end

      def revision_url(revision, anchor=false)
        "http://foo.bar/"
      end
    end

  end
end

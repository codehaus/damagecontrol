module DamageControl
  module ScmWeb
    class ViewCvs < Base
      register self

      attr_accessor :baseurl

      def initialize
        @baseurl = ""
      end

      def url
        RSCM::PathConverter.ensure_trailing_slash(baseurl)
      end

      def file_url(file)
        if(file.previous_native_revision_identifier)
          "#{url}#{file.path}?r1=#{file.previous_native_revision_identifier}&r2=#{file.native_revision_identifier}"
        else
          # point to the viewcvs (rev) and fisheye (r) revisions (no diff view)
          "#{url}#{file.path}?rev=#{file.native_revision_identifier}&r=#{file.native_revision_identifier}"
        end
      end

      def revision_url(revision)
        url
      end
    end
  end
end
module DamageControl
  module ScmWeb
    class ViewCVS
      attr_accessor :baseurl

      def initialize(baseurl)
        @baseurl = baseurl
      end

      def url
        RSCM::PathConverter.ensure_trailing_slash(baseurl)
      end

      def file_url(file, anchor=false)
        result = nil
        if(file.previous_native_revision_identifier)
          result = "#{url}#{file.path}?r1=#{file.previous_native_revision_identifier}&r2=#{file.native_revision_identifier}"
        else
          # point to the viewcvs (rev) and fisheye (r) revisions (no diff view)
          result = "#{url}#{file.path}?rev=#{file.native_revision_identifier}&r=#{file.native_revision_identifier}"
        end
        anchor ? "<a href=\"#{result}\">#{file.path}</a>" : result
      end

      def revision_url(revision, anchor=false)
        url
      end
    end
  end
end
require 'rscm/path_converter'

module RSCM
  module SCMWeb

    class Null
      def change_url(change, anchor=false)
        change.path
      end
    end

    class ViewCVS
      attr_accessor :baseurl

      def initialize(baseurl)
        @baseurl = baseurl
      end

      def url
        PathConverter.ensure_trailing_slash(baseurl)
      end

      def change_url(change, anchor=false)
        result = nil
        if(change.previous_revision)
          result = "#{url}#{change.path}?r1=#{change.previous_revision}&r2=#{change.revision}"
        else
          # point to the viewcvs (rev) and fisheye (r) revisions (no diff view)
          result = "#{url}#{change.path}?rev=#{change.revision}&r=#{change.revision}"
        end
        anchor ? "<a href=\"#{result}\">#{change.path}</a>" : result
      end

      def changeset_url(changeset, anchor=false)
        url
      end
    end

    class Fisheye < ViewCVS
      def changeset_url(changeset, anchor=false)
        # TODO: link to their faked CVS changesets (or proper SVN ones when that happens).
      end
    end

  end
end

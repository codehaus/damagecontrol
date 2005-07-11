require 'damagecontrol/scm_web/view_cvs'

module DamageControl
  module ScmWeb
    class Fisheye < ViewCvs
      register self

      def revision_url(revision)
        # TODO: link to their faked CVS revisions (or proper SVN ones when that happens).
      end
    end
  end
end
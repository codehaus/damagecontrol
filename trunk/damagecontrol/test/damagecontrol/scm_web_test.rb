require 'yaml'
require 'test/unit'
require 'rscm/revision'
require 'damagecontrol/scm_web'

module DamageControl
  module SCMWeb

    class SCMWebTest < Test::Unit::TestCase
    
      def setup
        @change = RSCM::RevisionFile.new("path/one", RSCM::RevisionFile::MODIFIED, "aslak", "Fixed CATCH-22", "2.4", Time.utc(2004,7,5,12,0,2))
      end

      def test_view_cvs
        view_cvs = ViewCVS.new("http://cvs.damagecontrol.codehaus.org/")
        assert_equal("http://cvs.damagecontrol.codehaus.org/path/one?rev=2.4&r=2.4", view_cvs.file_url(@change))
      end
    end

  end
end

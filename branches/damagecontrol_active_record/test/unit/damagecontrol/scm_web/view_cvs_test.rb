require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module ScmWeb
    class ViewCvsTest < Test::Unit::TestCase
      
      def setup
        @scm_web = ViewCvs.new
        @scm_web.baseurl = "http://cvs.damagecontrol.codehaus.org/"
      end

      def test_should_compute_link_for_added_files
        revision_file = RevisionFile.new
        revision_file.path = "path/one"
        revision_file.native_revision_identifier = "2.4"
        assert_equal("http://cvs.damagecontrol.codehaus.org/path/one?rev=2.4&r=2.4", @scm_web.file_url(revision_file))
      end

      def test_should_compute_link_for_modified_files
        revision_file = RevisionFile.new
        revision_file.path = "path/one"
        revision_file.native_revision_identifier = "2.4"
        revision_file.previous_native_revision_identifier = "2.3"
        assert_equal("http://cvs.damagecontrol.codehaus.org/path/one?r1=2.3&r2=2.4", @scm_web.file_url(revision_file))
      end
    end

  end
end

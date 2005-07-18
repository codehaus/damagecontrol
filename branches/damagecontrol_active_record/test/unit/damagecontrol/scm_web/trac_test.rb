require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module ScmWeb
    class TracTest < Test::Unit::TestCase
      fixtures :revisions, :revision_files
      
      def setup
        @trac = Trac.new
        @trac.changeset_url = "http://dev.rubyonrails.com/changeset"
      end

      def Xtest_should_compute_link_for_added_files
        revision_file = RevisionFile.new
        revision_file.path = "path/one"
        revision_file.native_revision_identifier = "2.4"
        assert_equal("http://cvs.damagecontrol.codehaus.org/path/one?rev=2.4&r=2.4", @view_cvs.file_url(revision_file))
      end

      def test_should_compute_link_for_modified_files
        assert_equal("http://dev.rubyonrails.com/changeset/1735#file2", @trac.file_url(@rails_1735_cgi))
      end
    end

  end
end
